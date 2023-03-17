//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseVault } from "./base/BaseVault.sol";

contract DekasinoUSDC is BaseVault {
    //Goerli Testnet USDC
    constructor() BaseVault(0xc59BbC7DE74f0247f63B50f2960F3ebF3ded2c5E, "Dekasino USDC", "dUSDC") {
        this;
    }
}
