//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

import "forge-std/console.sol";

contract Liquidity is IERC721Receiver {
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint24 public constant poolFee = 100;

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

    function getSqrtPriceX96(address _token0, address _token1) external view returns (uint160 sqrtPriceX96) {
        require(_token0 != _token1, "tokens must be different");
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(_token0, _token1, poolFee);

        address pool = PoolAddress.computeAddress(factory, poolKey);
        console.log("pool: ",pool);
        (sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();
    }

    function _getTicks(address _token0, address _token1, uint256 priceLower, uint256 priceUpper)
        external
        view
        returns (int24)
    {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(_token0, _token1, poolFee);
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        // int24 tickSpacing = pool.tickSpacing();
        console.log("token0:", pool.token0());
        console.log("token1:", pool.token1());
        (uint160 sqrtprice, int24 tick,,,,,) = pool.slot0();

        console.log("sqrtPrice:", uint256(sqrtprice));
        console.log("tick:", uint256(tick));

        // console.log("priceLower: ",priceLower);
        // console.log("priceUpper: ",priceUpper);

        // _tickLower = int24(log2((sqrt(priceLower) * 10001) / 10000));
        // _tickUpper = int24(log2((sqrt(priceUpper) * 10001) / 10000));

        // console.log("_tickLower: ", uint256(_tickLower));
        // console.log("_tickUpper: ", uint256(_tickUpper));

        // require(_tickLower % tickSpacing == 0, "tick lower");
        // require(_tickUpper % tickSpacing == 0, "tick upper");
        return tick;
    }

    function mintPosition(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        // int24 _tickLower,
        int24 tick,
        address _to
    ) external returns (uint256 tokenId, uint256 liquidity, uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: _token0,
            token1: _token1,
            fee: poolFee,
            tickLower: tick - 100,
            tickUpper: tick + 100,
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

    function decreaseLiquidityByHalf(uint256 _tokenId) external returns (uint256 amount0, uint256 amount1) {
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

        // _sendToOwner(_tokenId, amount0, amount1);
    }

    function increaseLiquidity(uint256 _tokenId, uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 liquidity, uint256 amount0, uint256 amount1)
    {
        require(msg.sender == deposits[_tokenId].owner, "caller is not owner");

        TransferHelper.safeTransferFrom(deposits[_tokenId].token0, msg.sender, address(this), _amount0);
        TransferHelper.safeTransferFrom(deposits[_tokenId].token1, msg.sender, address(this), _amount1);

        TransferHelper.safeApprove(deposits[_tokenId].token0, address(nonfungiblePositionManager), _amount0);
        TransferHelper.safeApprove(deposits[_tokenId].token1, address(nonfungiblePositionManager), _amount1);

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

    function getNFT(uint256 _tokenId) external {
        require(msg.sender == deposits[_tokenId].owner, "only owner allowed!");
        nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, _tokenId);

        delete deposits[_tokenId];
    }

    function getLiquidity(uint256 _tokenId) external view returns (uint128 lqdty) {
        (,,,,,,, lqdty,,,,) = nonfungiblePositionManager.positions(_tokenId);
    }
}
