// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/interfaces/IUniswapV2Router01.sol";
import "../../contracts/interfaces/IUniswapV2Pair.sol";


contract Testing {
    //Pool info
    address public addressSLP;
    address public addressTokenA;
    address public addressTokenB;

    IERC20 lp;
    IERC20 tokenA;
    IERC20 tokenB;
    IUniswapV2Pair sushiPair;

    //change pool info
    function changePoolInfo(address newAddressSLP) public {
        addressSLP = newAddressSLP;
        lp = IERC20(addressSLP); 

        sushiPair = IUniswapV2Pair(addressSLP);
        addressTokenA = sushiPair.token0();
        addressTokenB = sushiPair.token1();
        tokenA = IERC20(addressTokenA);
        tokenB = IERC20(addressTokenB); 
    }

    constructor(address newAddressSLP){
        changePoolInfo(newAddressSLP);
    }
}