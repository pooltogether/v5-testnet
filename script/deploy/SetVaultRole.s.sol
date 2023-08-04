// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetVaultRole is Helpers {
  function _setVaultsRole() internal {
    /* DAI */
    _yieldVaultGrantMinterRole(_getYieldVault("PTDAILY"), address(_getVault("PTDAILYT")));
    _yieldVaultGrantMinterRole(_getYieldVault("PTDAIHY"), address(_getVault("PTDAIHYT")));

    /* USDC */
    _yieldVaultGrantMinterRole(_getYieldVault("PTUSDCLY"), address(_getVault("PTUSDCLYT")));
    _yieldVaultGrantMinterRole(_getYieldVault("PTUSDCHY"), address(_getVault("PTUSDCHYT")));

    /* gUSD */
    _yieldVaultGrantMinterRole(_getYieldVault("PTGUSDY"), address(_getVault("PTGUSDT")));

    /* wBTC */
    _yieldVaultGrantMinterRole(_getYieldVault("PTWBTCY"), address(_getVault("PTWBTCT")));

    /* wETH */
    _yieldVaultGrantMinterRole(_getYieldVault("PTWETHY"), address(_getVault("PTWETHT")));
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    _setVaultsRole();
    vm.stopBroadcast();
  }
}
