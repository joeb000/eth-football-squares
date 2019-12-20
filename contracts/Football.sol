pragma solidity ^0.5.0;

import "./token/ERC20/IERC20.sol";
import "./access/ownership/owned.sol";

contract Football is owned {

    enum GamePhase { NotAGame, GameOpen, GameLocked, GameCompleted, WinnerPaid }

    struct Game {
        address erc20RewardToken;
        uint256 squarePrice;
        uint256 totalPot;
        uint256 startDateTime; //unix timestamp
        GamePhase phase;
        uint8[10] columns;
        uint8[10] rows;
        string meta;
        mapping (uint8 => address) squares;
        address owner;
        address winner;
        uint8[2] winningColRow; // first value is column index, second value is row index
    }

    uint256 public REFUND_AFTER_TIME_PERIOD = 3 days;

    mapping (bytes32 => Game) public games;

    mapping (address => uint256) public nonce;

    function createGame(address _rewardToken, uint256 _price, uint256 _date, string memory _meta) public {
        bytes32 gameId = getGameId(msg.sender, nonce[msg.sender]);
        games[gameId].owner = msg.sender;
        games[gameId].phase = GamePhase.GameOpen;
        games[gameId].erc20RewardToken = _rewardToken;
        games[gameId].squarePrice = _price;
        games[gameId].startDateTime = _date;
        games[gameId].meta = _meta;
        nonce[msg.sender]++;
        emit GameCreated(msg.sender, gameId, _rewardToken, _meta);
    }

    function pickSquareValue(bytes32 _gameId, uint8 _value) public {
        Game storage g = games[_gameId];
        require(g.phase == GamePhase.GameOpen, "game is not open");
        require(g.squares[_value]==address(0), "Square already occupied");
        require(IERC20(g.erc20RewardToken).transferFrom(msg.sender, address(this), g.squarePrice), "transfer failed");
        g.totalPot += g.squarePrice;
        g.squares[_value] = msg.sender;
        emit SquarePicked(msg.sender, _gameId, _value);
    }

    function pickMultipleSquares(bytes32 _gameId, uint8[] memory _values) public {
        Game storage g = games[_gameId];
        require(g.phase == GamePhase.GameOpen, "game is not open");
        for (uint8 i = 0; i < _values.length; i++) {
            require(g.squares[_values[i]]==address(0), "Square already occupied");
            g.totalPot += g.squarePrice;
            g.squares[_values[i]] = msg.sender;
            emit SquarePicked(msg.sender, _gameId, _values[i]);
        }
    }

    function pickSquare(bytes32 _gameId, uint8 _column, uint8 _row) public {
        // TODO check bounds
        uint8 choice = rowColumnToInt(_column, _row);
        pickSquareValue(_gameId, choice);
    }

    function shuffleGame(bytes32 _gameId) public {
        Game storage g = games[_gameId];
        require(g.owner == msg.sender, "not the game owner");
        require(g.phase == GamePhase.GameOpen, "Game not in open phase");
        g.columns = shuffle(block.timestamp);
        g.rows = shuffle(block.timestamp-1);
        g.phase = GamePhase.GameLocked;
    }


    function setWinner(bytes32 _gameId, uint8 _rowIndex, uint8 _colIndex) public {
        Game storage g = games[_gameId];
        require(g.owner == msg.sender, "not the game owner");
        require(g.phase == GamePhase.GameLocked, "Game is not locked");
        g.winningColRow[0] = _colIndex;
        g.winningColRow[1] = _rowIndex;
        g.phase = GamePhase.GameCompleted;
        address winner = getSquare(_gameId, g.winningColRow[0], g.winningColRow[1]);
        emit WinnerSet(_gameId, winner);
    }

    function claimReward(bytes32 _gameId) public {
        Game storage g = games[_gameId];
        require(g.phase == GamePhase.GameCompleted, "Game is not Completed");
        address winner = getSquare(_gameId, g.winningColRow[0], g.winningColRow[1]);
        require(msg.sender == winner, "You did not win");
        uint256 winnings = g.totalPot * 98 / 100; // -2% fee to the contract creator
        require(IERC20(g.erc20RewardToken).transfer(msg.sender, winnings), "winner transfer failed");
        g.phase = GamePhase.WinnerPaid;
        emit RewardClaimed(_gameId, winner, g.erc20RewardToken, winnings);
    }


    function collectFee(address _token, address _to) public onlyOwner {
        uint256 bal = IERC20(_token).balanceOf(address(this));
        require(IERC20(_token).transfer(_to, bal), "transfer failed");
    }

    function rowColumnToInt(uint8 row, uint8 column) public pure returns (uint8) {
        int lengthOfSide = 10;
        return uint8((lengthOfSide * row) + column);
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

    function getGameSquareValues(bytes32 _gameId) public view returns (address[100] memory values) {
        Game storage g = games[_gameId];
        for (uint8 i = 0; i < 100; i++) {
            values[i] = g.squares[i];
        }
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

    event GameCreated(address indexed owner, bytes32 gameId, address indexed token, string metadata);
    event WinnerSet(bytes32 gameId, address indexed winner);
    event RewardClaimed(bytes32 gameId, address indexed winner, address token, uint256 reward);
    event SquarePicked(address indexed picker, bytes32 gameId, uint8 squareIndex);
}