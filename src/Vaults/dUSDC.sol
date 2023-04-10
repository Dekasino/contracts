//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseVault } from "./base/BaseVault.sol";

contract DekasinoUSDC is BaseVault {
    //Fantom Testnet USDC
    constructor() BaseVault(0x2A07dAdC595Cb54F87dd14eaB4f16987be7303E4, "Dekasino USDC", "dUSDC") {
        this;
    }
}
