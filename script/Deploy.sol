// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { DekasinoUSDC } from "src/Vaults/dUSDC.sol";
import { DekasinoUSDT } from "src/Vaults/dUSDT.sol";

contract Deploy is Script {
    function run() external {
        string memory mnemonic = vm.envString("MNEMONIC");
        uint256 privKey = vm.deriveKey(mnemonic, 0);
        vm.startBroadcast(privKey);

        new DekasinoUSDC();
        new DekasinoUSDT();

        vm.stopBroadcast();
    }
}
