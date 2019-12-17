pragma solidity ^0.5.0;

import "./token/ERC20/IERC20.sol";
import "./access/ownership/owned.sol";

contract Football is owned {

    enum GamePhase { NotAGame, GameOpen, GameLocked, GameCompleted, WinnerPaid }

    struct Game {
        address erc20RewardToken;
        uint256 squarePrice;
        uint256 totalPot;
        GamePhase phase;
        uint8[10] columns;
        uint8[10] rows;
        string meta;
        mapping (uint8 => address) squares;
        address owner;
        uint8[2] winningColRow; // first value is column index, second value is row index
    }

    mapping (bytes32 => Game) public games;

    mapping (address => uint256) public nonce;

    function createGame(address _rewardToken, uint256 _price, string memory _meta) public {
        Game memory g;
        bytes32 gameId = getGameId(msg.sender, nonce[msg.sender]);
        games[gameId] = g;
        games[gameId].owner = msg.sender;
        games[gameId].phase = GamePhase.GameOpen;
        games[gameId].erc20RewardToken = _rewardToken;
        games[gameId].squarePrice = _price;
        games[gameId].meta = _meta;
        nonce[msg.sender]++;
    }

    function pickSquare(bytes32 _gameId, uint8 _column, uint8 _row) public {
        Game storage g = games[_gameId];

        // TODO check bounds
        uint8 choice = rowColumnToInt(_column, _row);
        require(g.phase == GamePhase.GameOpen, "game is not open");

        require(g.squares[choice]==address(0), "Square already occupied");

        require(IERC20(g.erc20RewardToken).transferFrom(msg.sender, address(this), g.squarePrice), "transfer failed");
        g.totalPot += g.squarePrice;
        g.squares[choice] = msg.sender;
    }

    function shuffleGame(bytes32 _gameId) public {
        Game storage g = games[_gameId];
        require(g.owner == msg.sender, "not the game owner");
        require(g.phase == GamePhase.GameOpen, "Game not in open phase");
        g.columns = shuffle(block.timestamp);
        g.rows = shuffle(block.timestamp-1);
        g.phase = GamePhase.GameLocked;
    }


    function setWinner(bytes32 _gameId, uint8 _colIndex, uint8 _rowIndex) public {
        Game storage g = games[_gameId];
        require(g.owner == msg.sender, "not the game owner");
        require(g.phase == GamePhase.GameLocked, "Game is not locked");
        g.winningColRow[0] = _colIndex;
        g.winningColRow[1] = _rowIndex;
        g.phase = GamePhase.GameCompleted;
    }

    function claimReward(bytes32 _gameId) public {
        Game storage g = games[_gameId];
        require(g.phase == GamePhase.GameCompleted, "Game is not Completed");
        address winner = getSquare(_gameId, g.winningColRow[0], g.winningColRow[1]);
        require(msg.sender == winner, "You did not win");
        uint256 winnings = g.totalPot * 98 / 100; // -2% fee to the contract creator
        require(IERC20(g.erc20RewardToken).transfer(msg.sender, winnings), "winner transfer failed");
        g.phase = GamePhase.WinnerPaid;
    }

    function collectFee(address _token, address _to) public onlyOwner {
        uint256 bal = IERC20(_token).balanceOf(address(this));
        require(IERC20(_token).transfer(_to, bal), "transfer failed");
    }

    function rowColumnToInt(uint8 column, uint8 row) public pure returns (uint8) {
        int lengthOfSide = 10;
        return uint8((lengthOfSide * column) + row);
    }

    function getSquare(bytes32 _gameId, uint8 _col, uint8 _row) public view returns (address) {
        Game storage g = games[_gameId];
        return g.squares[rowColumnToInt(_col, _row)];
    }
    function getSquareValue(bytes32 _gameId, uint8 i) public view returns (address) {
        Game storage g = games[_gameId];
        return g.squares[i];
    }

    function getGameColumns(bytes32 _gameId) public view returns (uint8[10] memory) {
        Game storage g = games[_gameId];
        return g.columns;
    }
    function getGameRows(bytes32 _gameId) public view returns (uint8[10] memory) {
        Game storage g = games[_gameId];
        return g.rows;
    }

    function getGameId(address _owner, uint _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _nonce));
    }

    // solidity implementation of https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    function shuffle(uint _seed) public pure returns (uint8[10] memory returnArray) {
        uint8 arrayIndex = 0;
        bool[] memory struckPositions = new bool[](10);
        uint randomEnough = uint(keccak256(abi.encodePacked(_seed)));
        for (uint8 i = 10; i > 0; i--) {
            randomEnough = uint(keccak256(abi.encodePacked(randomEnough)));
            uint8 pos = uint8(randomEnough % i);
            for (uint8 j = 0; j <= pos; j++) {
                if (struckPositions[j]) {
                    pos++;
                }
            }
            struckPositions[pos] = true;
            returnArray[arrayIndex] = pos;
            arrayIndex++;
        }
    }
}