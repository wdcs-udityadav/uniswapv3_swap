// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {FlashLoan} from "../src/FlashLoan.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityTest is Test {
    FlashLoan public flashLoan;

    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address user = vm.addr(1);

    function setUp() public {
        address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        flashLoan = new FlashLoan(swapRouter, factory, weth);
    }

    function testInitFlash() public {
        vm.startPrank(user);
        flashLoan.initFlash(
            FlashLoan.FlashParams({
                token0: address(DAI),
                token1: address(USDT),
                fee1: 100,
                amount0: 5000 * 1e18,
                amount1: 5000 * 1e6,
                fee2: 500,
                fee3: 1000
            })
        );
        vm.stopPrank();
    }
}
