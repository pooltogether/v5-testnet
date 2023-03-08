// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";

import { BaseSetup, IVault } from "test/utils/BaseSetup.t.sol";

contract AwardIntegrationTest is BaseSetup {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testAward() external {
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

    // TODO: add tests
    // assertEq(prizePool.prizeTokenPerShare().unwrap(), 0.045454545454545454e18);
    // assertEq(prizePool.reserve(), uint256(_prizeTokenContributed / 220e18) + 120); // remainder of the complex fraction
    // assertEq(prizePool.totalDrawLiquidity(), 10e18 - 120); // ensure not a single wei is lost!
  }
}
