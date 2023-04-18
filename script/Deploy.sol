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

        DekasinoUSDC usdc =  DekasinoUSDC(0x6e10B8a37Ab52d86986E4542Df4B93e6043Ef826);
        DekasinoUSDT usdt =  DekasinoUSDT(0x1ae35b05450808381BbA046E47e5198fAd068D48);
        DekasinoRoulette roulette = new DekasinoRoulette();

        usdc.setVaultController(address(roulette), true);
        usdt.setVaultController(address(roulette), true);

        roulette.setToken(address(usdc.underlying()), true, IVault(address(usdc)), 0.25 * 10**6, 100 * 10**6);
        roulette.setToken(address(usdt.underlying()), true, IVault(address(usdt)), 0.25 * 10**6, 100 * 10**6);

        vm.stopBroadcast();
    }
}
