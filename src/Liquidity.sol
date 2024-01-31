//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

contract Liquidity is IERC721Receiver, LiquidityManagement {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint24 public constant poolFee = 3000;

    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    struct Deposit {
        address owner;
        uint256 liquidity;
        address token0;
        address token1;
    }

    mapping(uint256 => Deposit) public deposits;

    constructor() {}

    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        _createDeposit(operator, tokenId);
        return this.onERC721Received.selector;
    }

    function _createDeposit(address owner, uint256 _tokenId) private {
        (,, address token0, address token1,,,, uint128 liquidity,,,,) = nonfungiblePositionManager.positions(_tokenId);
        deposits[_tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
    }
}
