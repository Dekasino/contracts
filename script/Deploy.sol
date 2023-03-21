// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { DekasinoUSDC } from "src/Vaults/dUSDC.sol";
import { DekasinoUSDT } from "src/Vaults/dUSDT.sol";
import { DekasinoRoulette } from "src/Games/DekasinoRoulette.sol";
import { IVault } from "src/Vaults/Interface/IVault.sol";

contract Deploy is Script {
    function run() external {
        string memory mnemonic = vm.envString("MNEMONIC");
        uint256 privKey = vm.deriveKey(mnemonic, 0);
        vm.startBroadcast(privKey);

        DekasinoUSDC usdc = DekasinoUSDC(0x601D504632182CE4dF9177c9962fa0053382F1AE);
        DekasinoUSDT usdt = DekasinoUSDT(0x4070403fEfD21D3379897361492F26DbBA6E639D);
        DekasinoRoulette roulette = new DekasinoRoulette();

        usdc.setVaultController(address(roulette), true);
        usdt.setVaultController(address(roulette), true);

        roulette.setToken(address(usdc.underlying()), true, IVault(address(usdc)), 0.25 ether, 100 ether);
        roulette.setToken(address(usdt.underlying()), true, IVault(address(usdt)), 0.25 ether, 100 ether);

        vm.stopBroadcast();
    }
}
