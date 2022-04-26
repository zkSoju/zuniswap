// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 initialSupply) ERC20(_name, _symbol){
      _mint(msg.sender, initialSupply);
    }
}
