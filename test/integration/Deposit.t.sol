// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";

import { BaseSetup, IVault } from "test/utils/BaseSetup.t.sol";

contract DepositIntegrationTest is BaseSetup {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testDeposit() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    _deposit(_amount, alice);

    assertEq(IERC20(vault).balanceOf(alice), _amount);
    assertEq(vault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _amount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);
    assertEq(IERC20(yieldVault).balanceOf(address(vault)), _amount);
    assertEq(yieldVault.balanceOf(address(vault)), _amount);

    vm.stopPrank();
  }

  function testSponsor() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    _sponsor(_amount, alice);

    assertEq(IERC20(vault).balanceOf(alice), _amount);
    assertEq(vault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(vault.balanceOf(SPONSORSHIP_ADDRESS), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), SPONSORSHIP_ADDRESS), 0);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);
    assertEq(IERC20(yieldVault).balanceOf(address(vault)), _amount);
    assertEq(yieldVault.balanceOf(address(vault)), _amount);

    vm.stopPrank();
  }

  function testDelegate() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    _deposit(_amount, alice);

    twabController.delegate(address(vault), bob);

    assertEq(IERC20(vault).balanceOf(alice), _amount);
    assertEq(vault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(IERC20(vault).balanceOf(bob), 0);
    assertEq(vault.balanceOf(bob), 0);

    assertEq(twabController.balanceOf(address(vault), bob), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), bob), _amount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);
    assertEq(IERC20(yieldVault).balanceOf(address(vault)), _amount);
    assertEq(yieldVault.balanceOf(address(vault)), _amount);

    vm.stopPrank();
  }
}
