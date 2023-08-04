// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/console2.sol";

import { Script } from "forge-std/Script.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";
import { VaultFactory } from "pt-v5-vault/VaultFactory.sol";

import { RNGBlockhash } from "rng/RNGBlockhash.sol";
import { RNGInterface } from "rng/RNGInterface.sol";
import { RngAuction } from "pt-v5-draw-auction/RngAuction.sol";
import { RngAuctionRelayerDirect } from "pt-v5-draw-auction/RngAuctionRelayerDirect.sol";
import { RngRelayAuction } from "pt-v5-draw-auction/RngRelayAuction.sol";

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployPool is Helpers {
  uint32 internal constant DRAW_PERIOD_SECONDS = 2 hours;

  function run() public {
    vm.startBroadcast();

    ERC20Mintable prizeToken = _getToken("POOL", _tokenDeployPath);
    TwabController twabController = new TwabController(1 days, uint32(block.timestamp));

    uint64 firstDrawStartsAt = uint64(block.timestamp);
    uint64 auctionDuration = DRAW_PERIOD_SECONDS / 4;
    uint64 auctionTargetSaleTime = auctionDuration / 2;

    console2.log("constructing rng stuff....");

    RNGBlockhash rng = new RNGBlockhash();

    RngAuction rngAuction = new RngAuction(
      rng,
      address(this),
      DRAW_PERIOD_SECONDS,
      firstDrawStartsAt,
      auctionDuration,
      auctionTargetSaleTime
    );

    RngAuctionRelayerDirect rngAuctionRelayerDirect = new RngAuctionRelayerDirect(rngAuction);

    console2.log("constructing prize pool....");

    PrizePool prizePool = new PrizePool(
      ConstructorParams(
        prizeToken,
        twabController,
        address(0),
        DRAW_PERIOD_SECONDS,
        firstDrawStartsAt, // drawStartedAt
        uint8(3), // minimum number of tiers
        100,
        10,
        10,
        ud2x18(0.9e18), // claim threshold of 90%
        sd1x18(0.9e18) // alpha
      )
    );

    console2.log("constructing auction....");

    RngRelayAuction rngRelayAuction = new RngRelayAuction(
      prizePool,
      address(rngAuctionRelayerDirect),
      auctionDuration,
      auctionTargetSaleTime
    );

    prizePool.setDrawManager(address(rngRelayAuction));

    new Claimer(prizePool, 0.0001e18, 1000e18, DRAW_PERIOD_SECONDS, ud2x18(0.5e18));

    LiquidationPairFactory liquidationPairFactory = new LiquidationPairFactory();
    new LiquidationRouter(liquidationPairFactory);

    new VaultFactory();

    vm.stopBroadcast();
  }
}
