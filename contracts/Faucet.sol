pragma solidity ^0.5.0;

import "./token/ERC20/IERC20.sol";
import "./access/ownership/owned.sol";

contract Faucet is owned {

    mapping (address => bool) public tapped;

    address public erc20TokenAddress;
    uint256 public amount;

    function set(address _a, uint256 _amt) public onlyOwner {
        erc20TokenAddress = _a;
        amount = _amt;
    }

    function tap() public {
        require(!tapped[msg.sender], "Already tapped");
        require(IERC20(erc20TokenAddress).transfer(msg.sender, amount),"transfer failed");
        tapped[msg.sender] = true;
    }

    function remaining() public view returns (uint256) {
        return IERC20(erc20TokenAddress).balanceOf(address(this));
    }
}