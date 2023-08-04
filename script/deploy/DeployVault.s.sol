// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { PrizePool, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { SD59x18, convert } from "prb-math/SD59x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployVault is Helpers {
  uint128 public constant ONE_POOL = 1e18;

  function _deployVault(
    YieldVaultMintRate _yieldVault,
    string memory _nameSuffix,
    string memory _symbolSuffix,
    uint128 _tokenOutPerPool
  ) internal returns (VaultMintRate vault) {
    ERC20 _underlyingAsset = ERC20(_yieldVault.asset());

    PrizePool prizePool = _getPrizePool();

    vault = new VaultMintRate(
      _underlyingAsset,
      string.concat("PoolTogether ", _underlyingAsset.name(), _nameSuffix, " Prize Token"),
      string.concat("PT", _underlyingAsset.symbol(), _symbolSuffix, "T"),
      _getTwabController(),
      _yieldVault,
      prizePool,
      _getClaimer(),
      msg.sender,
      100000000, // 0.1 = 10%
      msg.sender
    );

    vault.setLiquidationPair(_createPair(prizePool, vault, _tokenOutPerPool));
  }

  function _createPair(
    PrizePool _prizePool,
    VaultMintRate _vault,
    uint128 _tokenOutPerPool
  ) internal returns (LiquidationPair pair) {
    // this is approximately the maximum decay constant, as the CGDA formula requires computing e^(decayConstant * time).
    // since the data type is SD59x18 and e^134 ~= 1e58, we can divide 134 by the draw period to get the max decay constant.
    SD59x18 _decayConstant = convert(130).div(convert(int(uint(_prizePool.drawPeriodSeconds()))));
    pair = _getLiquidationPairFactory().createPair(
      ILiquidationSource(_vault),
      address(_getToken("POOL", _tokenDeployPath)),
      address(_vault),
      _prizePool.drawPeriodSeconds(),
      uint32(_prizePool.firstDrawStartsAt()),
      _prizePool.drawPeriodSeconds() / 2,
      _decayConstant,
      uint112(ONE_POOL),
      uint112(_tokenOutPerPool),
      uint112(_tokenOutPerPool) // Assume min is 1 POOL worth of the token
    );
  }

  function _deployVaults() internal {
    /* DAI */
    uint128 daiPerPool = _getExchangeRate(DAI_PRICE, 0);

    _deployVault(_getYieldVault("PTDAILY"), " Low Yield", "LY", daiPerPool);

    _deployVault(_getYieldVault("PTDAIHY"), " High Yield", "HY", daiPerPool);

    /* USDC */
    uint128 usdcPerPool = _getExchangeRate(USDC_PRICE, 12);

    _deployVault(_getYieldVault("PTUSDCLY"), " Low Yield", "LY", usdcPerPool);

    _deployVault(_getYieldVault("PTUSDCHY"), " High Yield", "HY", usdcPerPool);

    /* gUSD */
    uint128 gusdPerPool = _getExchangeRate(GUSD_PRICE, 16);

    _deployVault(_getYieldVault("PTGUSDY"), "", "", gusdPerPool);

    /* wBTC */
    uint128 wBtcPerPool = _getExchangeRate(WBTC_PRICE, 10);

    _deployVault(_getYieldVault("PTWBTCY"), "", "", wBtcPerPool);

    /* wETH */
    uint128 wEthPerPool = _getExchangeRate(ETH_PRICE, 0);

    _deployVault(_getYieldVault("PTWETHY"), "", "", wEthPerPool);
  }

  function run() public {
    vm.startBroadcast();
    _deployVaults();
    vm.stopBroadcast();
  }
}
