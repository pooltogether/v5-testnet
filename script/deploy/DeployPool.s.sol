// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

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

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { VaultMintRate } from "../../src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "../../src/YieldVaultMintRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployPool is Helpers {
  uint32 internal constant DRAW_PERIOD_SECONDS = 2 hours;

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

    ERC20Mintable prizeToken = _getToken("POOL", _tokenDeployPath);
    TwabController twabController = new TwabController(1 days, uint32(block.timestamp));

    PrizePool prizePool = new PrizePool(
      ConstructorParams(
        prizeToken,
        twabController,
        address(0),
        uint16(7), // grand prize should occur every 3.5 days
        DRAW_PERIOD_SECONDS,
        uint64(block.timestamp), // drawStartedAt
        uint8(3), // minimum number of tiers
        100,
        10,
        10,
        ud2x18(0.9e18), // claim threshold of 90%
        sd1x18(0.9e18) // alpha
      )
    );

    if (block.chainid == 5) {
      prizePool.setDrawManager(GOERLI_DEFENDER_ADDRESS);
    }

    if (block.chainid == 11155111) {
      prizePool.setDrawManager(SEPOLIA_DEFENDER_ADDRESS);
    }

    if (block.chainid == 80001) {
      prizePool.setDrawManager(MUMBAI_DEFENDER_ADDRESS);
    }

    new Claimer(prizePool, 0.0001e18, 1000e18, DRAW_PERIOD_SECONDS, ud2x18(0.5e18));

    LiquidationPairFactory liquidationPairFactory = new LiquidationPairFactory();
    new LiquidationRouter(liquidationPairFactory);

    new VaultFactory();

    vm.stopBroadcast();
  }
}
