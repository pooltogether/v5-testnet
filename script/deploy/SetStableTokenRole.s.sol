// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetStableTokenRole is Helpers {
  function run() public {
    vm.startBroadcast();
    /* DAI */
    ERC20Mintable dai = _getToken("DAI", _stableTokenDeployPath);
    _tokenGrantMinterRoles(dai);

    /* USDC */
    ERC20Mintable usdc = _getToken("USDC", _stableTokenDeployPath);
    _tokenGrantMinterRoles(usdc);

    /* gUSD */
    ERC20Mintable gUSD = _getToken("GUSD", _stableTokenDeployPath);
    _tokenGrantMinterRoles(gUSD);
    vm.stopBroadcast();
  }
}
