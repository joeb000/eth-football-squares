pragma solidity ^0.5.0;

import "./token/ERC20/ERC20.sol";
import "./access/ownership/owned.sol";

contract FootballToken is ERC20, owned {

    string public name;
    uint8 public decimals;
    string public symbol;
    
    constructor
    (
        string  memory _tokenName,
        string memory _tokenSymbol,
        uint8   _decimalUnits
    )
     public  {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }


    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to,_amount);
    }
}