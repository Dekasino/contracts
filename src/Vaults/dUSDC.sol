//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BaseVault} from "./base/BaseVault.sol";

contract DekasinoUSDC is BaseVault {
  //Goerli Testnet USDC
  constructor() BaseVault(0xC171863e9183fd08DFc3bEFc2a5992ad04997BFE,"Dekasino USDC","dUSDC") {
    this;
  }
}