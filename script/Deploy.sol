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
        string[] memory inputs = new string[](9);
        vm.startBroadcast(privKey);

        DekasinoUSDC usdc = new DekasinoUSDC();
        DekasinoUSDT usdt = new DekasinoUSDT();
        DekasinoRoulette roulette = new DekasinoRoulette();

        inputs[0] = "npx";
        inputs[1] = "@api3/airnode-admin";
        inputs[2] = "derive-sponsor-wallet-address";
        inputs[3] = "--airnode-xpub";
        inputs[4] =
            "xpub6CuDdF9zdWTRuGybJPuZUGnU4suZowMmgu15bjFZT2o6PUtk4Lo78KGJUGBobz3pPKRaN9sLxzj21CMe6StP3zUsd8tWEJPgZBesYBMY7Wo";
        inputs[5] = "--airnode-address";
        inputs[6] = "0x6238772544f029ecaBfDED4300f13A3c4FE84E1D";
        inputs[7] = "--sponsor-address";
        inputs[8] = string(abi.encodePacked(address(roulette)));
        bytes memory res = vm.ffi(inputs);
        console2.log(string(res));

        usdc.setVaultController(address(roulette), true);
        usdt.setVaultController(address(roulette), true);

        roulette.setToken(address(usdc.underlying()), true, IVault(address(usdc)), 0.25 ether, 100 ether);
        roulette.setToken(address(usdt.underlying()), true, IVault(address(usdt)), 0.25 ether, 100 ether);

        vm.stopBroadcast();
    }
}
