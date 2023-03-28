// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { PrizePool, SD59x18 } from "v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "v5-twab-controller/TwabController.sol";
import { Claimer, IVault } from "v5-vrgda-claimer/Claimer.sol";
import { ILiquidationSource } from "v5-liquidator/interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "v5-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "v5-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "v5-liquidator/LiquidationRouter.sol";
import { UFixed32x9 } from "v5-liquidator-libraries/FixedMathLib.sol";

import { ERC20Mintable } from "src/ERC20Mintable.sol";
import { VaultMintRate } from "src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "src/YieldVaultMintRate.sol";

import { Helpers } from "script/helpers/Helpers.sol";

contract DeployVault is Helpers {
  function _deployVault(
    YieldVaultMintRate _yieldVault,
    string memory _nameSuffix,
    string memory _symbolSuffix,
    uint128 _virtualReserveOut
  ) internal returns (VaultMintRate vault) {
    ERC20 _underlyingAsset = ERC20(_yieldVault.asset());
    string memory _underlyingAssetName = _underlyingAsset.name();
    string memory _underlyingAssetSymbol = _underlyingAsset.symbol();

    vault = new VaultMintRate(
      _underlyingAsset,
      string.concat("PoolTogether ", _underlyingAssetName, _nameSuffix, " Prize Token"),
      string.concat("PT", _underlyingAssetSymbol, _symbolSuffix, "T"),
      _getTwabController(),
      _yieldVault,
      _getPrizePool(),
      _getClaimer(),
      msg.sender
    );

    ERC20Mintable _prizeToken = _getToken("POOL", _tokenDeployPath);
    LiquidationPairFactory _liquidationPairFactory = _getLiquidationPairFactory();

    LiquidationPair liquidationPair = _liquidationPairFactory.createPair(
      ILiquidationSource(vault),
      address(_prizeToken),
      address(vault),
      UFixed32x9.wrap(0.3e9),
      UFixed32x9.wrap(0.02e9),
      1e18,
      _virtualReserveOut
    );

    vault.setLiquidationPair(liquidationPair);
  }

  function _deployVaults() internal {
    /* DAI */
    YieldVaultMintRate daiLowYieldVault = _getYieldVault("PTDAILY");
    _deployVault(daiLowYieldVault, " Low Yield", "LY", _getExchangeRate(DAI_PRICE, 0));

    YieldVaultMintRate daiHighYieldVault = _getYieldVault("PTDAIHY");
    _deployVault(daiHighYieldVault, " High Yield", "HY", _getExchangeRate(DAI_PRICE, 0));

    /* USDC */
    YieldVaultMintRate usdcLowYieldVault = _getYieldVault("PTUSDCLY");
    _deployVault(usdcLowYieldVault, " Low Yield", "LY", _getExchangeRate(USDC_PRICE, 12));

    YieldVaultMintRate usdcHighYieldVault = _getYieldVault("PTUSDCHY");
    _deployVault(usdcHighYieldVault, " High Yield", "HY", _getExchangeRate(USDC_PRICE, 12));

    /* gUSD */
    YieldVaultMintRate gUSDYieldVault = _getYieldVault("PTGUSDY");
    _deployVault(gUSDYieldVault, "", "", _getExchangeRate(GUSD_PRICE, 16));

    /* wBTC */
    YieldVaultMintRate wBTCYieldVault = _getYieldVault("PTWBTCY");
    _deployVault(wBTCYieldVault, "", "", _getExchangeRate(WBTC_PRICE, 10));

    /* wETH */
    YieldVaultMintRate wETHYieldVault = _getYieldVault("PTWETHY");
    _deployVault(wETHYieldVault, "", "", _getExchangeRate(ETH_PRICE, 0));
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    _deployVaults();
    vm.stopBroadcast();
  }
}
