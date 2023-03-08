// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";

import { IntegrationBaseSetup, IVault } from "test/utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "test/utils/Helpers.t.sol";

contract ClaimIntegrationTest is IntegrationBaseSetup, Helpers {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testClaim() external {
    uint256 _amount = 1000e18;
    uint256 _yield = 10e18;

    vm.startPrank(alice);

    _mint(underlyingAsset, _amount, alice);
    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    _accrueYield(underlyingAsset, vault, _yield);
    prizeToken.mint(alice, 1000e18);

    vm.startPrank(alice);

    (uint256 _alicePrizeTokenBalanceBefore, uint256 _prizeTokenContributed) = _liquidate(
      liquidationRouter,
      liquidationPair,
      prizeToken,
      _yield,
      alice
    );

    vm.stopPrank();

    _award(prizePool, winningRandomNumber);

    uint8 _tier = uint8(1);
    uint8[] memory _tiers = new uint8[](1);
    _tiers[0] = _tier;

    uint256 _prizeSize = prizePool.calculatePrizeSize(_tier);
    uint256 _prizePoolBalanceBeforeClaim = prizeToken.balanceOf(address(prizePool));
    uint256 _alicePrizeTokenBalanceBeforeClaim = prizeToken.balanceOf(alice);

    uint256 _claimFees = _claim(claimer, vault, prizePool, alice, _tiers);

    assertEq(
      prizeToken.balanceOf(alice),
      _alicePrizeTokenBalanceBeforeClaim + (_prizeSize - _claimFees)
    );
    assertEq(prizeToken.balanceOf(address(prizePool)), _prizePoolBalanceBeforeClaim - _prizeSize);

    // TODO: check that a tier that was claimed can't be claimed again
    // vm.expectRevert("");
    _claim(claimer, vault, prizePool, alice, _tiers);
  }
}
