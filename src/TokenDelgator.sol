// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenDelegator {
    mapping(address => mapping(address => bool)) public approvals;
    
    function approve(address _user) public {
        approvals[_user][msg.sender] = true;
    }

    function transferToken(
        IERC20 token,
        address _from,
        address _to,
        uint256 _amount
    ) public {
        token.transferFrom(_from, address(this), _amount);
        token.transfer(_to, _amount);
    }
}
