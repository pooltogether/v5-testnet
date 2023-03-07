// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";

import { BaseSetup, IVault } from "test/utils/BaseSetup.t.sol";

contract LiquidateIntegrationTest is BaseSetup {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testLiquidate() external {
    uint256 _yield = 10e18;
    _accrueYield(_yield);

    vm.startPrank(alice);

    (uint256 _alicePrizeTokenBalanceBefore, uint256 _prizeTokenContributed) = _liquidate(_yield, alice);

    assertEq(prizeToken.balanceOf(address(prizePool)), _prizeTokenContributed);
    assertEq(prizeToken.balanceOf(alice), _alicePrizeTokenBalanceBefore - _prizeTokenContributed);

    // Because of the yield smooting, only 10% of the prize tokens contributed can be awarded.
    assertEq(prizePool.getContributedBetween(address(vault), 1, 1), _prizeTokenContributed * 10 / 100);

    assertEq(IERC20(vault).balanceOf(alice), _yield);
    assertEq(vault.balanceOf(alice), _yield);

    vm.stopPrank();
  }
}
