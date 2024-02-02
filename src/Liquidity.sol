//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

contract Liquidity is IERC721Receiver {
    address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

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

    function mintPosition(address _token0, address _token1, uint256 _amount0, uint256 _amount1, address _to)
        external
        returns (uint256 tokenId, uint256 liquidity, uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: _token0,
            token1: _token1,
            fee: poolFee,
            tickLower: TickMath.MIN_TICK,
            tickUpper: TickMath.MAX_TICK,
            amount0Desired: _amount0,
            amount1Desired: _amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: _to,
            deadline: block.timestamp
        });

        TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), _amount0);
        TransferHelper.safeTransferFrom(_token1, msg.sender, address(this), _amount1);
        TransferHelper.safeApprove(_token0, address(nonfungiblePositionManager), _amount0);
        TransferHelper.safeApprove(_token1, address(nonfungiblePositionManager), _amount1);

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
        _createDeposit(msg.sender, tokenId);

        if (amount0 < _amount0) {
            TransferHelper.safeApprove(_token0, address(nonfungiblePositionManager), 0);
            TransferHelper.safeTransferFrom(_token0, address(this), msg.sender, _amount0 - amount0);
        }

        if (amount1 < _amount1) {
            TransferHelper.safeApprove(_token1, address(nonfungiblePositionManager), 0);
            TransferHelper.safeTransferFrom(_token1, address(this), msg.sender, _amount1 - amount1);
        }
    }

    function collectFees(uint256 _tokenId, address _to) external returns (uint256 amount0, uint256 amount1) {
        nonfungiblePositionManager.safeTransferFrom(msg.sender, address(this), _tokenId);

        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: _tokenId,
            recipient: _to,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function decreaseLiquidity(uint256 _tokenId) external returns (uint256 amount0, uint256 amount1) {
        require(msg.sender == deposits[_tokenId].owner, "caller is not owner");

        uint256 newLiquidity = deposits[_tokenId].liquidity / 2;
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: _tokenId,
            liquidity: uint128(newLiquidity),
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

        _sendToOwner(_tokenId, amount0, amount1);
    }

    function _sendToOwner(uint256 _tokenId, uint256 _amount0, uint256 _amount1) internal {
        address owner = deposits[_tokenId].owner;

        address token0 = deposits[_tokenId].token0;
        address token1 = deposits[_tokenId].token1;

        TransferHelper.safeTransfer(token0, owner, _amount0);
        TransferHelper.safeTransfer(token1, owner, _amount1);
    }

    function increaseLiquidity(uint256 _tokenId, uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 liquidity, uint256 amount0, uint256 amount1)
    {
        require(msg.sender == deposits[_tokenId].owner, "caller is not owner");

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: _tokenId,
            amount0Desired: _amount0,
            amount1Desired: _amount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
    }
}
