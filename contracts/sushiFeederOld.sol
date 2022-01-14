// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
 * @title Sushi Feeder
 * @dev Providing liquidity to a sushiswap liquidity pool
 */
contract SushiFeeder is ERC721URIStorage {
    address tokenAaddress = 0x96Ca4dD98De66e9A591528D849Bcb5d051ACAF5C;
    address tokenBaddress = 0x4252017A3262B40e9567250133B542BAD79Fd523; 
    address[] path = [tokenAaddress, tokenBaddress];
    address sushiRouterAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address addressSLP = 0x5b93d73B75fa586FAdd65e5023Af4A884693B973;
    address sushiAddress = 0x9dBC5fbc89572E9525E8e65B15C24137A57a8f60;
    
    ERC721 myNFTs = ERC721(address(this));
    IERC20 public tokenA = IERC20(tokenAaddress);
    IERC20 public tokenB = IERC20(tokenBaddress); 
    IERC20 public lp = IERC20(addressSLP); 
    IERC20 public sushi = IERC20(sushiAddress);
    IUniswapV2Router01 public sushiSwapRouter = IUniswapV2Router01(sushiRouterAddress); 

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    event NewNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("SushiFeeder", "FEED") {
    }

    function buyNFT(uint amount) public {
        tokenA.transferFrom(msg.sender, address(this), amount);

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, "https://jsonkeeper.com/b/6AZA");

        _tokenIds.increment();

        emit NewNFTMinted(msg.sender, newItemId);
        
        uint swapAmount = SafeMath.div(amount, 2);
        swapTokens(amount, swapAmount);
        addLiquiditytoPool(swapAmount);
        depositSLP();
    }

    function swapTokens (uint amount, uint swapAmount) public {
        uint minSwapAmount = SafeMath.mul(swapAmount, SafeMath.div(95, 100));
        uint256 deadline = block.timestamp;
        tokenA.approve(sushiRouterAddress, amount);
        sushiSwapRouter.swapExactTokensForTokens(swapAmount,minSwapAmount,path,address(this),deadline); 
    }

    function addLiquiditytoPool (uint swapAmount) public {
        uint amountADesired = swapAmount;
        uint amountBDesired = swapAmount;
        uint amountAMin = SafeMath.mul(amountADesired, SafeMath.div(95, 100));
        uint amountBMin = SafeMath.mul(amountBDesired, SafeMath.div(95, 100));
        uint256 deadline = block.timestamp;

        tokenB.approve(sushiRouterAddress, swapAmount);
        sushiSwapRouter.addLiquidity(
            tokenAaddress, 
            tokenBaddress, 
            amountADesired, 
            amountBDesired, 
            amountAMin, 
            amountBMin, 
            address(this), 
            deadline);
    }

    function depositSLP() public {
        uint amount = lp.balanceOf(address(this));
        lp.approve(msg.sender, amount);
        lp.transfer(msg.sender, amount);
    }
    
    function totalSupply() public view returns(uint) {
        return _tokenIds.current();
    }

    //split rewards 1st of the month evenly
    function payingOutRewards() public {
        uint balance = sushi.balanceOf(address(this));
        uint amountNFTs = totalSupply();
        uint payoutAmount = SafeMath.div(balance, amountNFTs);

        for (uint i=0; i<amountNFTs;i++){
            sushi.transfer(myNFTs.ownerOf(i), payoutAmount);
        }
    }
}
