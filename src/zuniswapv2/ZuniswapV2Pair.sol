pragma solidity 0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Math} from "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address user) external returns (uint256);
}

error InsufficientLiquidityMinted();
error TransferFailed();

contract ZuniswapV2Pair is ERC20, Math {
    uint256 private constant MINIMUM_LIQUIDITY = 1;

    uint256 private reserve0;
    uint256 private reserve1;

    address private token0;
    address private token1;

    event Mint(address, uint256, uint256);

    constructor(address _token0, address _token1)
        ERC20("Zuniswap-V1", "ZUNI-V2", 18)
    {
        token0 = _token0;
        token1 = _token1;
    }

    function mint() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // calculate deposits by subtracting current balance with balance before deposits are counted
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 liquidity;

        // MINIMUM_LIQUIDITY at 1000 makes one LP share 1000x cheaper
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // chosen underlying token is the minimum of the two to penalize unbalanced liquidity provision
            // resulting minted LP tokens is proportional to chosen underlying deposit with reserves
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, liquidity);

        // update reserve balances to new balances after LP tokens minted
        _update(balance0, balance1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function burn() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[msg.sender];

        // calculate proportion of reserves to allocate to user
        uint256 amount0 = (liquidity * balance0) / totalSupply;
        uint256 amount1 = (liquidity * balance1) / totalSupply;

        if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityMinted();

        // burn all LP tokens
        _burn(msg.sender, liquidity);

        _safeTransfer(token0, msg.sender, amount0);
        _safeTransfer(token1, msg.sender, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
    }

    function _update(uint256 balance0, uint256 balance1) internal {
        reserve0 = balance0;
        reserve1 = balance1;
    }

    function getReserves()
        public
        view
        returns (
            uint256,
            uint256,
            uint32
        )
    {
        return (reserve0, reserve1, 0);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(("transfer(address,uint256)"), to, value)
        );
        // success == false || data == false
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }
}
