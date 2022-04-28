pragma solidity 0.8.13;

import "./Exchange.sol";

contract Factory {
    mapping(address => address) public tokenToExchange;

    function createExchange(address _tokenAddress) public returns (address) {
        // check for zero address
        require(_tokenAddress != address(0), "invalid token address");
        // check exchange for token is not already created
        require(
            tokenToExchange[_tokenAddress] == address(0),
            "exchange already exists"
        );

        // new deploys a new contract
        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}
