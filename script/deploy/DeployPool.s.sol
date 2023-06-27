// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";

import { PrizePool, ConstructorParams, SD59x18 } from "v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "v5-twab-controller/TwabController.sol";
import { Claimer } from "v5-vrgda-claimer/Claimer.sol";
import { ILiquidationSource } from "v5-liquidator/interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "v5-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "v5-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "v5-liquidator/LiquidationRouter.sol";

import { ERC20Mintable } from "src/ERC20Mintable.sol";
import { VaultMintRate } from "src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "src/YieldVaultMintRate.sol";

import { Helpers } from "script/helpers/Helpers.sol";

contract DeployPool is Helpers {
  uint32 internal constant DRAW_PERIOD_SECONDS = 1 hours;

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

    vm.stopBroadcast();
  }
}
