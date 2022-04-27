// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Exchange} from "../Exchange.sol";
import {Token} from "../Token.sol";

import "@std/Test.sol";

contract ExchangeTest is Test {
    using stdStorage for StdStorage;

    Exchange exchange;
    Token token;
    address user;
    address lp;

    function setUp() public {
        console.log(unicode"🧪 Testing Exchange...");
        token = new Token("Zuni", "ZNI", 1000);
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

        // Test slippage

        // With values that exceed/attempt to drain pool the exchange rate is different than
        // what you would expect (constant product formula)
        console.log(exchange.getTokenAmount(1));
        console.log(exchange.getTokenAmount(100));
        console.log(exchange.getTokenAmount(1000));

        console.log(exchange.getEthAmount(2));
        console.log(exchange.getEthAmount(200));
        console.log(exchange.getEthAmount(2000));
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
        exchange.ethToTokenSwap{value: 10}(18);
        assertEq(token.balanceOf(user), 18);
        vm.stopPrank();

        vm.startPrank(lp, lp);
        assertEq(lp.balance, 0);
        assertEq(token.balanceOf(lp), 0);
        console.log(lp.balance);
        // we receive about 109.9 ethers and 181.98 tokens
        exchange.removeLiquidity(100);
        console.log("lp after balance", token.balanceOf(lp));

        vm.stopPrank();
    }
}
