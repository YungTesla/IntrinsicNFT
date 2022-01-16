// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
 * @title Sushi Feeder
 * @dev Providing liquidity to a sushiswap liquidity pool
 */
contract SushiFeeder is ERC721URIStorage { 
    // NFT starting price and current price
    uint public startPriceNFT = 1e17;
    uint public newPriceNFT = startPriceNFT;

    // pool info
    address public addressSLP;
    IERC20 lp;
    IERC20 tokenA;
    IERC20 tokenB;

    // sushi swap router for swapping and adding liquidity
    IUniswapV2Router01 sushiRouter = IUniswapV2Router01(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);  

    //WETH for NFT payment
    IERC20 weth = IERC20(0x3419157200A5cBC5008C6DFdd620893029D2cF36);
    
    // farm rewards
    IERC20 sushi = IERC20(0x9dBC5fbc89572E9525E8e65B15C24137A57a8f60);

    // NFT collection
    ERC721 myNFTs = ERC721(address(this));

    // counter for NFT minting
    using Counters for Counters.Counter;
    Counters.Counter  _tokenIds;

    // events
    event NewNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("SushiFeeder", "FEED") {
        addressSLP = 0x5b93d73B75fa586FAdd65e5023Af4A884693B973;
        IUniswapV2Pair sushiPair = IUniswapV2Pair(addressSLP);
        changePoolInfo(sushiPair);
    }

    // change pool info
    function changePoolInfo(IUniswapV2Pair sushiPair) private {
        addressSLP = address(sushiPair);
        lp = IERC20(addressSLP); 

        // IUniswapV2Pair sushiPair = IUniswapV2Pair(addressSLP);
        address addressTokenA = sushiPair.token0();
        address addressTokenB = sushiPair.token1();
        tokenA = IERC20(addressTokenA);
        tokenB = IERC20(addressTokenB); 
    }

    // remove Pool
    function removeLiquidity() private {
    // approve router to transfer lp tokens
        uint amountLP = lp.balanceOf(address(this));
        lp.approve(address(sushiRouter),amountLP);

        uint amountAMin = 0;
        uint amountBMin = 0;
        uint256 deadline = block.timestamp;

        sushiRouter.removeLiquidity(address(tokenA), address(tokenB), amountLP, amountAMin, amountBMin, address(this), deadline);
    }

    function changePool(address newAddressSLP) public {
        // remove liquidity
        removeLiquidity();

        // swap old tokens to new tokenA
        IUniswapV2Pair newSushiPair = IUniswapV2Pair(newAddressSLP);
        address newTokenA = newSushiPair.token0();
        
        swap(address(tokenA), newTokenA, tokenA.balanceOf(address(this)));
        swap(address(tokenB), newTokenA, tokenB.balanceOf(address(this)));

        // change pool info
        changePoolInfo(newSushiPair);
        
        //swap half of tokenA for tokenB
        uint amount = SafeMath.div(tokenA.balanceOf(address(this)),2);
        swap(address(tokenA), address(tokenB), amount);

        addLiquidity();
        // farmstaking
    }

    function swap(address _tokenA, address _tokenB, uint _amount) private {
        IERC20 token = IERC20(_tokenA);
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;

        token.approve(address(sushiRouter), _amount);

        uint256 deadline = block.timestamp;
        sushiRouter.swapExactTokensForTokens(_amount,0,path,address(this),deadline); 
    }

    function createNFT() private {
        weth.transferFrom(msg.sender, address(this), newPriceNFT);
        newPriceNFT = SafeMath.add(newPriceNFT, startPriceNFT);

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, "https://jsonkeeper.com/b/6AZA");

        _tokenIds.increment();

        emit NewNFTMinted(msg.sender, newItemId);
    }

    function buyNewNFT() public {
        // mint new NFT
        createNFT();

        // swap weth to tokenA
        uint amountWETH = weth.balanceOf(address(this));
        swap(address(weth), address(tokenA), amountWETH);

        // swap half of tokenA for tokenB
        uint amountTokenA = tokenA.balanceOf(address(this));
        uint swapAmount = SafeMath.div(amountTokenA, 2);
        swap(address(tokenA), address(tokenB), swapAmount);
        
        // add liquidity
        addLiquidity();

        // farm staking
        // farmSLP();
    }

    function addLiquidity() private {
        uint amountADesired = tokenA.balanceOf(address(this));
        uint amountBDesired = tokenB.balanceOf(address(this));

        uint amountAMin = SafeMath.mul(amountADesired, SafeMath.div(90, 100));
        uint amountBMin = SafeMath.mul(amountBDesired, SafeMath.div(90, 100));
        uint256 deadline = block.timestamp;

        tokenA.approve(address(sushiRouter), amountADesired);
        tokenB.approve(address(sushiRouter), amountBDesired);
        sushiRouter.addLiquidity(address(tokenA),address(tokenB),amountADesired,amountBDesired,amountAMin,amountBMin,address(this),deadline);
    }

    function farmSLP() private {
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