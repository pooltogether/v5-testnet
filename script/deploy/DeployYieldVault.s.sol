// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployYieldVault is Helpers {
  function _deployYieldVault(
    ERC20Mintable _underlyingAsset,
    string memory _nameSuffix,
    string memory _symbolSuffix
  ) internal returns (YieldVaultMintRate) {
    string memory _underlyingAssetName = _underlyingAsset.name();
    string memory _underlyingAssetSymbol = _underlyingAsset.symbol();

    return
      new YieldVaultMintRate(
        _underlyingAsset,
        string.concat("PoolTogether ", _underlyingAssetName, " ", _nameSuffix, " Yield"),
        string.concat("PT", _underlyingAssetSymbol, _symbolSuffix, "Y"),
        msg.sender
      );
  }

  function _deployYieldVaults() internal {
    /* DAI */
    ERC20Mintable dai = _getToken("DAI", _stableTokenDeployPath);
    _deployYieldVault(dai, "Low", "L");
    _deployYieldVault(dai, "High", "H");

    /* USDC */
    ERC20Mintable usdc = _getToken("USDC", _stableTokenDeployPath);
    _deployYieldVault(usdc, "Low", "L");
    _deployYieldVault(usdc, "High", "H");

    /* gUSD */
    ERC20Mintable gUSD = _getToken("GUSD", _stableTokenDeployPath);
    _deployYieldVault(gUSD, "", "");

    /* wBTC */
    ERC20Mintable wBTC = _getToken("WBTC", _tokenDeployPath);
    _deployYieldVault(wBTC, "", "");

    /* wETH */
    ERC20Mintable wETH = _getToken("WETH", _tokenDeployPath);
    _deployYieldVault(wETH, "", "");
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    _deployYieldVaults();
    vm.stopBroadcast();
  }
}
