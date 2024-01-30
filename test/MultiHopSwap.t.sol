// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {MultiHopSwap} from "../src/MultiHopSwap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiHopSwapTest is Test {
    MultiHopSwap public multiHopSwap;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        multiHopSwap = new MultiHopSwap();
    }

    function testSwapExactInput() public {
        address user = vm.addr(1);
        deal(address(DAI), user, 500 * 1e18, true);

        vm.startPrank(user);
        assertEq(IERC20(DAI).balanceOf(user), 500 * 1e18);
        assertEq(IERC20(WETH9).balanceOf(user), 0);

        IERC20(DAI).approve(address(multiHopSwap), 400 * 1e18);
        uint256 amountOut = multiHopSwap.swapExactInput(400 * 1e18);
        assertEq(IERC20(DAI).balanceOf(user), 100 * 1e18);
        assertEq(IERC20(WETH9).balanceOf(user), amountOut);

        vm.stopPrank();
    }

    function testSwapExactOutput() public {
        address user = vm.addr(2);
        deal(address(DAI), user, 500 * 1e18, true);

        vm.startPrank(user);
        assertEq(IERC20(DAI).balanceOf(user), 500 * 1e18);
        assertEq(IERC20(WETH9).balanceOf(user), 0);

        IERC20(DAI).approve(address(multiHopSwap), 450 * 1e18);
        uint256 amountIn = multiHopSwap.swapExactOutput(172474261682099250, 450 * 1e18);
        console.log("amountIn: ", amountIn);
        console.log("weth bal: ", IERC20(WETH9).balanceOf(user));
        vm.stopPrank();
    }
}
