// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { IERC20, IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import { DrawBeacon, RNGInterface } from "v5-draw-beacon/DrawBeacon.sol";
import { PrizePool, SD59x18 } from "v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "v5-twab-controller/TwabController.sol";
import { Claimer, IVault } from "v5-vrgda-claimer/Claimer.sol";
import { ILiquidationSource } from "v5-liquidator/interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "v5-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "v5-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "v5-liquidator/LiquidationRouter.sol";
import { UFixed32x4 } from "v5-liquidator-libraries/FixedMathLib.sol";
import { Vault } from "v5-vault/Vault.sol";
import { YieldVault } from "v5-vault-mock/YieldVault.sol";

import { Utils } from "./Utils.t.sol";

contract ForkBaseSetup is Test {
  /* ============ Variables ============ */
  Utils internal utils;

  address payable[] internal users;
  address internal owner;
  address internal manager;
  address internal alice;
  address internal bob;

  address public constant SPONSORSHIP_ADDRESS = address(1);

  Vault public vault;
  string public vaultName = "PoolTogether aEthDAI Prize Token (PTaEthDAI)";
  string public vaultSymbol = "PTaEthDAI";

  address public underlyingAssetAddress;
  IERC20 public underlyingAsset;

  address public prizeTokenAddress;
  IERC20 public prizeToken;

  LiquidationRouter public liquidationRouter;
  LiquidationPair public liquidationPair;

  Claimer public claimer;
  DrawBeacon public drawBeacon;
  PrizePool public prizePool;

  uint256 public winningRandomNumber = 123456;
  uint32 public drawPeriodSeconds = 1 days;
  TwabController public twabController;

  /* ============ setUp ============ */
  function forkSetUp(IERC4626 _yieldVault) public {
    utils = new Utils();

    users = utils.createUsers(4);
    owner = users[0];
    manager = users[1];
    alice = users[2];
    bob = users[3];

    vm.label(owner, "Owner");
    vm.label(manager, "Manager");
    vm.label(alice, "Alice");
    vm.label(bob, "Bob");

    underlyingAssetAddress = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC token on Ethereum
    underlyingAsset = IERC20(underlyingAssetAddress);

    prizeTokenAddress = address(0x0cEC1A9154Ff802e7934Fc916Ed7Ca50bDE6844e); // POOL token on Ethereum
    prizeToken = IERC20(prizeTokenAddress);

    twabController = new TwabController(drawPeriodSeconds);

    uint64 drawStartsAt = uint64(block.timestamp);

    prizePool = new PrizePool(
      prizeToken,
      twabController,
      uint32(365), // 52 weeks = 1 year
      drawPeriodSeconds,
      drawStartsAt,
      uint8(2), // minimum number of tiers
      100e18,
      10e18,
      10e18,
      ud2x18(0.9e18), // claim threshold of 90%
      sd1x18(0.9e18) // alpha
    );

    drawBeacon = new DrawBeacon(
      address(this),
      prizePool,
      RNGInterface(address(0x3A06B40C67515cda47E44b57116488F73A441F72)), // RNGChainlinkV2 on Mainnet
      uint32(1),
      drawStartsAt,
      drawPeriodSeconds,
      uint32(7200)
    );

    claimer = new Claimer(prizePool, 0.0001e18, 1000e18, drawPeriodSeconds, ud2x18(0.5e18));

    vault = new Vault(
      underlyingAsset,
      vaultName,
      vaultSymbol,
      twabController,
      _yieldVault,
      prizePool,
      claimer,
      address(this),
      100000000, // 0.1 = 10%
      address(this)
    );

    vm.makePersistent(address(vault));

    uint128 _virtualReserveIn = 10e18;
    uint128 _virtualReserveOut = 5e18;
    uint256 _minK = (uint256(_virtualReserveIn * _virtualReserveOut) * 0.8e18) / 1e18;

    liquidationPair = new LiquidationPair(
      ILiquidationSource(vault),
      address(prizeToken),
      address(vault),
      UFixed32x4.wrap(0.3e4),
      UFixed32x4.wrap(0.02e4),
      _virtualReserveIn,
      _virtualReserveOut,
      _minK
    );

    vault.setLiquidationPair(liquidationPair);

    liquidationRouter = new LiquidationRouter(new LiquidationPairFactory());
  }
}
