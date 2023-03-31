//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseVault } from "./base/BaseVault.sol";

contract DekasinoUSDT is BaseVault {
    //Fantom Testnet USDT
    constructor() BaseVault(0xCDDd3bfFCa16Bf8A891718ADB6A9c051871B674C, "Dekasino USDT", "dUSDT") {
        this;
    }
}
