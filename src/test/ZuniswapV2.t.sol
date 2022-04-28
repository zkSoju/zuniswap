// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {ZuniswapV2Pair} from "../zuniswapv2/ZuniswapV2Pair.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import "@std/Test.sol";

contract ZuniswapV2Test is Test {
    MockERC20 token0;
    MockERC20 token1;
    ZuniswapV2Pair pair;

    function setUp() public {
        token0 = new MockERC20("Silver", "SLV", 18);
        token1 = new MockERC20("Gold", "GLD", 18);
        pair = new ZuniswapV2Pair(address(token0), address(token1));

        token0.mint(address(1337), 1000);
        token1.mint(address(1337), 1000);
        token0.mint(address(0xBEEF), 1000);
        token1.mint(address(0xBEEF), 1000);
        token0.mint(address(420), 1000);
        token1.mint(address(420), 1000);
    }

    function testMint() public {
        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        pair.mint();

        assertEq(pair.balanceOf(address(1337)), 100 - 1);
        assertReserves(100, 100);
        assertEq(pair.totalSupply(), 100);
    }

    function testMintWhenTheresLiquidity() public {
        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        pair.mint();

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        pair.mint();

        assertEq(pair.balanceOf(address(1337)), 200 - 1);
        assertReserves(200, 200);
        assertEq(pair.totalSupply(), 200);
    }

    function testMintUnbalanced() public {
        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        pair.mint();

        assertReserves(100, 100);
        console.log(pair.balanceOf(address(1337)));

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 500);

        pair.mint();

        assertReserves(200, 600);
        console.log(pair.balanceOf(address(1337)));
    }

    function testBurn() public {
        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        assertEq(token0.balanceOf(address(1337)), 900);
        assertEq(token1.balanceOf(address(1337)), 900);

        pair.mint();
        pair.burn();

        assertEq(pair.balanceOf(address(1337)), 0);
        assertReserves(1, 1);
        assertEq(token0.balanceOf(address(1337)), 999);
        assertEq(token1.balanceOf(address(1337)), 999);
    }

    function testBurnUnbalanced() public {
        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        pair.mint();

        token0.transfer(address(pair), 200);
        token1.transfer(address(pair), 100);

        pair.mint();
        pair.burn();

        // Expect a small penalty for adding unbalanced liquidity
        assertReserves(2, 1);
        assertEq(token0.balanceOf(address(1337)), 1000 - 2);
        assertEq(token1.balanceOf(address(1337)), 1000 - 1);
    }

    function testBurnUnbalancedDifferentUsers() public {
        startHoax(address(0xBEEF), address(0xBEEF), 0);
        token0.transfer(address(pair), 100);
        token1.transfer(address(pair), 100);

        pair.mint();

        vm.stopPrank();

        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 200);
        token1.transfer(address(pair), 100);

        pair.mint();
        pair.burn();

        // Expect a penalty for unbalanced provisioning (25%)
        assertEq(token0.balanceOf(address(1337)), 1000 - 50);
        // Expect no loss for depositing after pool is initialized by another user
        assertEq(token1.balanceOf(address(1337)), 1000);
        assertReserves(150, 100);

        vm.stopPrank();

        startHoax(address(0xBEEF), address(0xBEEF), 0);
        pair.burn();

        // Seems like initializing user receives penalty of penalizing user
        console.log(token0.balanceOf(address(0xBEEF)));
        console.log(token1.balanceOf(address(0xBEEF)));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        console.log(reserve0, reserve1);
    }

    function testBurnUnbalanceMultipleUsers() public {
        startHoax(address(0xBEEF), address(0xBEEF), 0);
        token0.transfer(address(pair), 1000);
        token1.transfer(address(pair), 1000);

        pair.mint();

        vm.stopPrank();

        startHoax(address(420), address(420), 0);
        token0.transfer(address(pair), 1000);
        token1.transfer(address(pair), 1000);

        pair.mint();

        vm.stopPrank();

        startHoax(address(1337), address(1337), 0);

        token0.transfer(address(pair), 200);
        token1.transfer(address(pair), 100);

        pair.mint();
        pair.burn();

        // Expect a penalty for unbalanced provisioning
        // Larger the difference between expected provisioning and actual, larger the penalty
        // Larger the reserves in comparison to deposit, the larger the penalty
        // (y tho? don't you skew the reserves more for smaller reserve balances?)
        assertEq(token0.balanceOf(address(1337)), 1000 - 96);
        // Expect no loss for depositing after pool is initialized by another user
        assertEq(token1.balanceOf(address(1337)), 1000);
        assertReserves(2096, 2000);

        vm.stopPrank();

        startHoax(address(0xBEEF), address(0xBEEF), 0);
        pair.burn();

        // Seems like initializing user receives penalty of penalizing user
        console.log(token0.balanceOf(address(0xBEEF)));
        console.log(token1.balanceOf(address(0xBEEF)));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        console.log(reserve0, reserve1);
    }

    function assertReserves(uint256 expectedReserve0, uint256 expectedReserve1)
        internal
    {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }
}
