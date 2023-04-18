//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseVault } from "./base/BaseVault.sol";

contract DekasinoUSDT is BaseVault {
    //Fantom Testnet USDT
    constructor() BaseVault(0x6eCe4F315C0F7cC369d8D0eABdAC361328527bAc, "Dekasino USDT", "dUSDT") {
        this;
    }
}
