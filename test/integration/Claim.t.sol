// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";

import { AlreadyClaimedPrize } from "pt-v5-prize-pool/PrizePool.sol";

import { IntegrationBaseSetup } from "../utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "../utils/Helpers.t.sol";

contract ClaimIntegrationTest is IntegrationBaseSetup, Helpers {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testFailClaim() external {
    uint256 _amount = 1000e18;
    uint256 _yield = 10e18;

    vm.startPrank(alice);

    underlyingAsset.mint(alice, _amount);
    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    _accrueYield(underlyingAsset, yieldVault, _yield);
    prizeToken.mint(alice, 1000e18);

    vm.startPrank(alice);

    uint256 maxAmountOut = liquidationPair.maxAmountOut();

    _liquidate(liquidationRouter, liquidationPair, prizeToken, maxAmountOut, alice);

    vm.stopPrank();

    _award(prizePool, winningRandomNumber);

    uint8 _tier = uint8(1);
    uint8[] memory _tiers = new uint8[](1);
    _tiers[0] = _tier;

    uint256 _prizeSize = prizePool.getTierPrizeSize(_tier);
    uint256 _prizePoolBalanceBeforeClaim = prizeToken.balanceOf(address(prizePool));
    uint256 _alicePrizeTokenBalanceBeforeClaim = prizeToken.balanceOf(alice);

    uint32[] memory _prizeIndices = new uint32[](1);
    _prizeIndices[0] = 0;

    uint256 _claimFees = _claim(claimer, vault, prizePool, alice, _prizeIndices, _tiers);

    assertEq(
      prizeToken.balanceOf(alice),
      _alicePrizeTokenBalanceBeforeClaim + (_prizeSize - _claimFees)
    );

    assertEq(
      prizeToken.balanceOf(address(prizePool)),
      _prizePoolBalanceBeforeClaim - (_prizeSize - _claimFees)
    );

    // Fails here with the error AlreadyClaimedPrize
    _claim(claimer, vault, prizePool, alice, _prizeIndices, _tiers);
  }
}
