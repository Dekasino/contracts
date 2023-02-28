//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./base/BaseVault.sol";

contract DekasinoUSDT is BaseVault {
  //Testnet USDT
  constructor() BaseVault(0xbcb313f45Ad20a0465954a0d4Cb73c0450E31b4c,"Dekasino USDT","dUSDT") {
    this;
  }
}