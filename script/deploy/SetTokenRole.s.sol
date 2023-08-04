// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetTokenRole is Helpers {
  function run() public {
    vm.startBroadcast();
    /* wBTC */
    ERC20Mintable wBTC = _getToken("WBTC", _tokenDeployPath);
    _tokenGrantMinterRoles(wBTC);

    /* wETH */
    ERC20Mintable wETH = _getToken("WETH", _tokenDeployPath);
    _tokenGrantMinterRoles(wETH);

    /* prizeToken */
    ERC20Mintable prizeToken = _getToken("POOL", _tokenDeployPath);
    _tokenGrantMinterRoles(prizeToken);
    vm.stopBroadcast();
  }
}
