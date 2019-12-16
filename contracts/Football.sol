pragma solidity ^0.5.0;

contract Football {

    struct Game {
        uint8[10] columns;
        uint8[10] rows;
        string meta;
        mapping (uint8 => address) squares;
        address owner;
    }

    mapping (address => Game) public games;
    // Game public currentGame;

    uint public testTime;

    function createGame(string memory _meta) public {
        Game memory g;
        games[msg.sender] = g;
        games[msg.sender].owner = msg.sender;
        games[msg.sender].meta = _meta;
    }

    function resetGame() public {
        Game memory g;
        games[msg.sender] = g;
    }

    function pickSquare(address _owner, uint8 _column, uint8 _row) public {
        Game storage g = games[_owner];

        // TODO check bounds
        uint8 choice = rowColumnToInt(_column, _row);
        require (g.squares[choice]==address(0), "Square already occupied");
        g.squares[choice] = msg.sender;
    }

    function shuffleGame() public {
        testTime = block.timestamp;
        Game storage g = games[msg.sender];
        g.columns = shuffle(block.timestamp);
        g.rows = shuffle(block.timestamp-1);
    }

    function rowColumnToInt(uint8 column, uint8 row) public pure returns (uint8) {
        int lengthOfSide = 10;
        return uint8((lengthOfSide * column) + row);
    }

    function getSquare(address _owner, uint8 _col, uint8 _row) public view returns (address) {
        Game storage g = games[_owner];
        return g.squares[rowColumnToInt(_col, _row)];
    }
    function getSquareValue(address _owner, uint8 i) public view returns (address) {
        Game storage g = games[_owner];
        return g.squares[i];
    }

    function getGameColumns(address _owner) public view returns (uint8[10] memory) {
        Game storage g = games[_owner];
        return g.columns;
    }
    function getGameRows(address _owner) public view returns (uint8[10] memory) {
        Game storage g = games[_owner];
        return g.rows;
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