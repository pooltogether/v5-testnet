// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { PrizePool, SD59x18 } from "v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "v5-twab-controller/TwabController.sol";
import { Claimer } from "v5-vrgda-claimer/Claimer.sol";
import { ILiquidationSource } from "v5-liquidator/interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "v5-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "v5-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "v5-liquidator/LiquidationRouter.sol";
import { UFixed32x4 } from "v5-liquidator-libraries/FixedMathLib.sol";

import { ERC20Mintable } from "src/ERC20Mintable.sol";
import { VaultMintRate } from "src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "src/YieldVaultMintRate.sol";

import { Helpers } from "script/helpers/Helpers.sol";

contract DeployVault is Helpers {
  function _getMinK(
    uint128 _virtualReserveIn,
    uint128 _virtualReserveOut
  ) internal pure returns (uint256 minK) {
    return (uint256(_virtualReserveIn * _virtualReserveOut) * 0.8e18) / 1e18;
  }

  function _deployVault(
    YieldVaultMintRate _yieldVault,
    string memory _nameSuffix,
    string memory _symbolSuffix,
    uint128 _virtualReserveOut,
    uint256 _minK
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
      msg.sender,
      100000000, // 0.1 = 10%
      msg.sender
    );

    LiquidationPairFactory _liquidationPairFactory = _getLiquidationPairFactory();

    LiquidationPair _liquidationPair = _liquidationPairFactory.createPair(
      ILiquidationSource(vault),
      address(_getToken("POOL", _tokenDeployPath)),
      address(vault),
      UFixed32x4.wrap(0.3e4),
      UFixed32x4.wrap(0.02e4),
      1e18,
      _virtualReserveOut,
      _minK
    );

    vault.setLiquidationPair(_liquidationPair);
  }

  function _deployVaults() internal {
    /* DAI */
    uint128 _virtualReserveIn = 1e18;
    uint128 _virtualReserveOutDai = _getExchangeRate(DAI_PRICE, 0);

    _deployVault(
      _getYieldVault("PTDAILY"),
      " Low Yield",
      "LY",
      _virtualReserveOutDai,
      _getMinK(_virtualReserveIn, _virtualReserveOutDai)
    );

    _deployVault(
      _getYieldVault("PTDAIHY"),
      " High Yield",
      "HY",
      _virtualReserveOutDai,
      _getMinK(_virtualReserveIn, _virtualReserveOutDai)
    );

    /* USDC */
    uint128 _virtualReserveOutUsdc = _getExchangeRate(USDC_PRICE, 12);

    _deployVault(
      _getYieldVault("PTUSDCLY"),
      " Low Yield",
      "LY",
      _virtualReserveOutUsdc,
      _getMinK(_virtualReserveIn, _virtualReserveOutUsdc)
    );

    _deployVault(
      _getYieldVault("PTUSDCHY"),
      " High Yield",
      "HY",
      _virtualReserveOutUsdc,
      _getMinK(_virtualReserveIn, _virtualReserveOutUsdc)
    );

    /* gUSD */
    uint128 _virtualReserveOutGusd = _getExchangeRate(GUSD_PRICE, 16);

    _deployVault(
      _getYieldVault("PTGUSDY"),
      "",
      "",
      _virtualReserveOutGusd,
      _getMinK(_virtualReserveIn, _virtualReserveOutGusd)
    );

    /* wBTC */
    uint128 _virtualReserveOutWBtc = _getExchangeRate(WBTC_PRICE, 10);

    _deployVault(
      _getYieldVault("PTWBTCY"),
      "",
      "",
      _virtualReserveOutWBtc,
      _getMinK(_virtualReserveIn, _virtualReserveOutWBtc)
    );

    /* wETH */
    uint128 _virtualReserveOutWEth = _getExchangeRate(ETH_PRICE, 0);

    _deployVault(
      _getYieldVault("PTWETHY"),
      "",
      "",
      _virtualReserveOutWEth,
      _getMinK(_virtualReserveIn, _virtualReserveOutWEth)
    );
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    _deployVaults();
    vm.stopBroadcast();
  }
}
