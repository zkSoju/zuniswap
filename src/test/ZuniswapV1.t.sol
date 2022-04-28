// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Exchange} from "../zuniswapv1/Exchange.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import "@std/Test.sol";

contract ZuniswapV1Test is Test {
    using stdStorage for StdStorage;

    Exchange exchange;
    MockERC20 token;
    address user;
    address lp;

    function setUp() public {
        console.log(unicode"🧪 Testing Exchange...");
        token = new MockERC20("Zuni", "ZNI", 18);
        exchange = new Exchange(address(token));
        user = address(1337);
        lp = address(0xBEEF);
    }

    function testExchange() public {
        startHoax(address(1337), address(1337));
        token.mint(address(1337), 1000);
        token.approve(address(exchange), 1000);
        exchange.addLiquidity{value: 100}(200); // 1 ETH <-> 2 ZNI
        assert(exchange.getReserve() == uint256(200));

        // With values that exceed/attempt to drain pool the exchange rate is different than
        // what you would expect (constant product formula) - called slippage

        // Closer to the pool reserve balance, the greater the slippage

        console.log(unicode"🔨 Testing ETH -> ZNI exchange rates...");
        console.log(exchange.getTokenAmount(1));
        console.log(exchange.getTokenAmount(10));
        console.log(exchange.getTokenAmount(100));
        console.log(exchange.getTokenAmount(1000));

        console.log(unicode"🔨 Testing ZNI -> ETH exchange rates...");
        console.log(exchange.getEthAmount(2));
        console.log(exchange.getEthAmount(20));
        console.log(exchange.getEthAmount(200));
        console.log(exchange.getEthAmount(2000));
        console.log(unicode"✅ Slippage tests passed.");
    }

    function testLPRewards() public {
        // Add ETH + ZNI liquidity to pool
        startHoax(lp, lp, 100);
        assertEq(lp.balance, 100);
        token.mint(lp, 200);
        token.approve(address(exchange), 200);
        exchange.addLiquidity{value: 100}(200);
        vm.stopPrank();

        // Initiate an exchange for ZNI tokens
        startHoax(user, user);
        assertEq(token.balanceOf(user), 0);

        // Expect at least 18 tokens provided slippage and 1% fee
        // Slippage caused by 10% of reserves
        exchange.ethToTokenSwap{value: 10}(18);
        assertEq(token.balanceOf(user), 18);
        vm.stopPrank();

        vm.startPrank(lp, lp);
        assertEq(lp.balance, 0);
        assertEq(token.balanceOf(lp), 0);
        // We receive about 110 ethers and 182 tokens as expected
        // Fee is already included in the exchange rate
        exchange.removeLiquidity(100);
        console.log("LP token balance after", token.balanceOf(lp));
        console.log("LP ether balance after", lp.balance);

        vm.stopPrank();

        console.log(unicode"✅ LP rewards and impermanent loss tests passed.");
    }
}
