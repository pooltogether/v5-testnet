// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";

import { BaseSetup, IVault } from "test/utils/BaseSetup.t.sol";

contract ClaimIntegrationTest is BaseSetup {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testClaim() external {
    uint256 _amount = 1000e18;
    uint256 _yield = 10e18;

    vm.startPrank(alice);

    _deposit(_amount, alice);

    vm.stopPrank();

    _accrueYield(_yield);

    vm.startPrank(alice);

    (, uint256 _prizeTokenContributed) = _liquidate(_yield, alice);

    vm.stopPrank();

    _award();

    uint8 _tier = uint8(1);
    uint8[] memory _tiers = new uint8[](1);
    _tiers[0] = _tier;

    uint256 _prizeSize = prizePool.calculatePrizeSize(_tier);
    uint256 _prizePoolBalanceBeforeClaim = prizeToken.balanceOf(address(prizePool));

    uint256 _claimFees = _claim(alice, _tiers);

    assertEq(prizeToken.balanceOf(alice), _prizeSize - _claimFees);
    assertEq(prizeToken.balanceOf(address(prizePool)), _prizePoolBalanceBeforeClaim - _prizeSize);

    // TODO: check that a tier that was claimed can't be claimed again
    // vm.expectRevert("");
    _claim(alice, _tiers);
  }
}
