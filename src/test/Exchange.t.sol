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
        exchange = Exchange(address(this));
        token = Token("Zuni", "ZUNI", 1000);
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testExchange() public {
        startHoax(address(1337), address(1337));
        token.approve(address(exchange), 1000);
        exchange.addLiquidity(1000);
        assert(exchange.getReserve() == uint256(1000));
    }

}