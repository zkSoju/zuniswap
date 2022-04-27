// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Exchange} from "../Exchange.sol";
import {Token} from "../Token.sol";

import "@std/Test.sol";

contract ExchangeTest is Test {
    using stdStorage for StdStorage;

    Exchange exchange;
    Token token;

    function setUp() public {
        console.log(unicode"🧪 Testing Exchange...");
        token = new Token("Zuni", "ZNI", 1000);
        exchange = new Exchange(address(token));
    }

    function testExchange() public {
        startHoax(address(1337), address(1337));
        token.mint(address(1337), 1000);
        token.approve(address(exchange), 1000);
        exchange.addLiquidity{value: 100}(200); // 1 ETH <-> 2 ZUNI
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
}
