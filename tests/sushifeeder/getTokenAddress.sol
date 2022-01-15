// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Testing {
    address public addressTokenA = 0x5f457593B26F005c5262d53bcCfe08459f0746B6;
    IERC20 public tokenA = IERC20(addressTokenA);

    function viewAdress() public view returns(address){
        return address(tokenA);
    }
}