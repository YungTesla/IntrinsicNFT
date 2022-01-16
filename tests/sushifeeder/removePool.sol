// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/interfaces/IUniswapV2Router01.sol";


contract Testing {
    address sushiRouterAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    IUniswapV2Router01 public sushiSwapRouter = IUniswapV2Router01(sushiRouterAddress); 

    function swap(address _tokenA, address _tokenB, uint _amount) public {
            IERC20 tokenA = IERC20(_tokenA);
            address[] memory path = new address[](2);
            path[0] = _tokenA;
            path[1] = _tokenB;

            tokenA.approve(sushiRouterAddress, _amount);

            uint256 deadline = block.timestamp;
            sushiSwapRouter.swapExactTokensForTokens(_amount,0,path,address(this),deadline); 
    }

    function swapping() public {
        address tokenA = 0x15f878888b534b18A3C0a465845774a4CF259cE9;
        address tokenB = 0x4252017A3262B40e9567250133B542BAD79Fd523;
        uint amount = 5e17;
        swap(tokenA, tokenB, amount);
    }
}