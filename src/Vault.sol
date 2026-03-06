// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vault {

    address public immutable TOKEN;
    address public immutable FACTORY;

    uint256 public totalDeposits;

    mapping(address => uint256) public balances;

    constructor(address _token, address _factory) {
        TOKEN = _token;
        FACTORY = _factory;
    }

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    function _onlyFactory() internal view {
        require(msg.sender == FACTORY, "not factory");
    }

    function deposit(address user, uint256 amount) external onlyFactory {
        balances[user] += amount;
        totalDeposits += amount;
    }
}