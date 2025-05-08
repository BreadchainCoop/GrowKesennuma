// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Allowlist {
    mapping(address => bool) public isAllowed;
    address public owner;

    event UserAllowed(address indexed user);
    event UsersBatchAllowed(address[] users);
    event OwnerChanged(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function allow(address _user) external onlyOwner {
        require(_user != address(0), "Invalid user address");
        require(!isAllowed[_user], "User already allowed");
        
        isAllowed[_user] = true;
        emit UserAllowed(_user);
    }

    function batchAllow(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            if (_users[i] != address(0) && !isAllowed[_users[i]]) {
                isAllowed[_users[i]] = true;
            }
        }
        emit UsersBatchAllowed(_users);
    }

    function isAllowlisted(address _user) external view returns (bool) {
        return isAllowed[_user];
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
} 