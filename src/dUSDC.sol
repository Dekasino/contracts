//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./base/BaseVault.sol";

contract DekasinoUSDC is BaseVault {
  //Testnet USDC
  constructor() BaseVault(0xbcb313f45Ad20a0465954a0d4Cb73c0450E31b4c,"Dekasino USDC","dUSDC") {
    this;
  }
}