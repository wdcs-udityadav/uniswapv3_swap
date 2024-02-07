// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {Liquidity} from "../src/Liquidity.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LiquidityTest is Test {
    Liquidity public liquidity;

    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address user = vm.addr(1);

    function setUp() public {
        liquidity = new Liquidity();
    }

    function testMintPosition() public returns (uint256) {
        uint256 dai_amount = 1000 * 1e18;
        uint256 usdt_amount = 1000 * 1e6;
        deal(address(DAI), user, dai_amount, true);
        deal(address(USDT), user, usdt_amount, true);

        uint256 priceLower = 9.8 * 1e6;
        uint256 priceUpper = 1.003 * 1e6;

        vm.startPrank(user);
        assertEq(DAI.balanceOf(user), dai_amount);
        assertEq(USDT.balanceOf(user), usdt_amount);

        TransferHelper.safeApprove(address(DAI), address(liquidity), dai_amount);
        TransferHelper.safeApprove(address(USDT), address(liquidity), usdt_amount);

        (int24 _tick) = liquidity._getTicks(address(DAI), address(USDT), priceLower, priceUpper);

        (uint256 tokenId, uint256 lqd, uint256 amount0, uint256 amount1) =
            liquidity.mintPosition(address(DAI), address(USDT), dai_amount, usdt_amount, _tick, user);

        console.log("tokenId: ", tokenId);
        console.log("liquidity: ", lqd);
        console.log("amount0: ", amount0 / 1e18);
        console.log("amount1: ", amount1 / 1e6);

        assertEq(nonfungiblePositionManager.ownerOf(tokenId), user);

        vm.stopPrank();
        return tokenId;
    }

    // function testCollectFees() public {
    //     uint256 _tokenId = testMintPosition();

    //     vm.startPrank(user);
    //     IERC721(address(nonfungiblePositionManager)).approve(address(liquidity), _tokenId);
    //     (uint256 amount0, uint256 amount1) = liquidity.collectFees(_tokenId, address(user));
    //     console.log("fee 0: ", amount0);
    //     console.log("fee 1: ", amount1);
    //     vm.stopPrank();
    // }

    // function testIncreaseLiquidity() public returns (uint256) {
    //     uint256 _tokenId = testMintPosition();

    //     uint256 daiAmount = 500 * 1e18;
    //     uint256 usdtAmount = 500 * 1e6;

    //     deal(address(DAI), user, daiAmount, true);
    //     deal(address(USDT), user, usdtAmount, true);

    //     vm.startPrank(user);
    //     assertEq(DAI.balanceOf(user), 500 * 1e18);
    //     assertEq(USDT.balanceOf(user), 500 * 1e6);
    //     TransferHelper.safeApprove(address(DAI), address(liquidity), daiAmount);
    //     TransferHelper.safeApprove(address(USDT), address(liquidity), usdtAmount);

    //     (uint256 liq, uint256 amount0, uint256 amount1) = liquidity.increaseLiquidity(_tokenId, daiAmount, usdtAmount);
    //     console.log("liquidity added: ", liq);
    //     console.log("amount0: ", amount0 / 1e18);
    //     console.log("amount1: ", amount1 / 1e6);

    //     console.log("total liquidity.: ", liquidity.getLiquidity(_tokenId));
    //     vm.stopPrank();
    //     return _tokenId;
    // }

    // function testDecreaseLiquidity() public {
    //     uint256 _tokenId = testIncreaseLiquidity();

    //     vm.startPrank(user);
    //     IERC721(address(nonfungiblePositionManager)).approve(address(liquidity), _tokenId);
    //     (uint256 amount0, uint256 amount1) = liquidity.decreaseLiquidityByHalf(_tokenId);
    //     console.log("amount0: ", amount0 / 1e18);
    //     console.log("amount1: ", amount1 / 1e6);

    //     console.log("liquidity after decrease: ", liquidity.getLiquidity(_tokenId));
    //     console.log("..... collect fees.....");

    //     liquidity.collectFees(_tokenId, address(user));
    //     console.log(" dai bal: ", DAI.balanceOf(user) / 1e18);
    //     console.log(" usdt bal: ", USDT.balanceOf(user) / 1e6);

    //     vm.stopPrank();
    // }
}
