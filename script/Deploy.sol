// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { DekasinoUSDC } from "src/Vaults/dUSDC.sol";
import { DekasinoUSDT } from "src/Vaults/dUSDT.sol";
import { DekasinoRoulette } from "src/Games/DekasinoRoulette.sol";
import { IVault } from "src/Vaults/Interface/IVault.sol";

contract Deploy is Script {
    function run() external {
        string memory mnemonic = vm.envString("MNEMONIC");
        uint256 privKey = vm.deriveKey(mnemonic, 0);
        vm.startBroadcast(privKey);

        DekasinoUSDC usdc = DekasinoUSDC(0x9444E189dfd09b3FBEBA502A87891bcEC5101fb5);
        DekasinoUSDT usdt = DekasinoUSDT(0x04CaC941FBBFfA2273678A292d098efa9E88932F);
        DekasinoRoulette roulette = new DekasinoRoulette();

        usdc.setVaultController(address(roulette), true);
        usdt.setVaultController(address(roulette), true);

        roulette.setToken(address(usdc.underlying()), true, IVault(address(usdc)), 0.25 ether, 100 ether);
        roulette.setToken(address(usdt.underlying()), true, IVault(address(usdt)), 0.25 ether, 100 ether);

        vm.stopBroadcast();
    }
}
