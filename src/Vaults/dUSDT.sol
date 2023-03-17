//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseVault } from "./base/BaseVault.sol";

contract DekasinoUSDT is BaseVault {
    //Goerli Testnet USDT
    constructor() BaseVault(0x8A41086C56dea8F821cfe35bC844Ec7b182Cd0F9, "Dekasino USDT", "dUSDT") {
        this;
    }
}
