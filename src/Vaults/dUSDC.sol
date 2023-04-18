//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseVault } from "./base/BaseVault.sol";

contract DekasinoUSDC is BaseVault {
    //Fantom Testnet USDC
    constructor() BaseVault(0x243365e3B61617D3E70f544510871c23F6C242EE, "Dekasino USDC", "dUSDC") {
        this;
    }
}
