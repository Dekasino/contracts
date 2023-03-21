// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DekasinoUSDC } from "src/Vaults/dUSDC.sol";
import { DekasinoRoulette } from "src/Games/DekasinoRoulette.sol";
import { IVault } from "src/Vaults/Interface/IVault.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

contract RouletteTest is PRBTest, StdCheats {
    DekasinoUSDC internal dusdc;
    IERC20Metadata internal usdc;
    DekasinoRoulette internal roulette;
    uint128[38] internal bets;

    function setUp() external {
        dusdc = new DekasinoUSDC();
        roulette = new DekasinoRoulette();
        usdc = dusdc.underlying();

        dusdc.setVaultController(address(roulette), true);
        roulette.setToken(address(dusdc.underlying()), true, IVault(address(dusdc)), 0.25 ether, 100 ether);

        deal(address(usdc), address(this), 1e35, true);
        vm.deal(address(this), 1 ether);
        usdc.approve(address(dusdc), type(uint256).max);
        usdc.approve(address(roulette), type(uint256).max);
        dusdc.deposit(1e25);

        for (uint256 i; i < 38; i++) {
            //if (i % 2 == 0) continue;
            bets[i] = uint128(0.1 ether + (i * 100));
        }
    }

    function testGas() external {
        roulette.placeBet{ value: 0.01 ether }(address(usdc), bets);
    }
}
