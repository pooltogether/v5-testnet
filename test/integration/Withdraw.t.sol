// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";

import { IntegrationBaseSetup } from "../utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "../utils/Helpers.t.sol";

contract WithdrawIntegrationTest is IntegrationBaseSetup, Helpers {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */

  /* ============ Withdraw ============ */
  function testWithdrawFullAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    _deposit(underlyingAsset, vault, _amount, alice);
    vault.withdraw(vault.maxWithdraw(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);
    assertEq(yieldVault.balanceOf(address(vault)), 0);

    vm.stopPrank();
  }

  function testWithdrawHalfAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    uint256 _halfAmount = _amount / 2;
    underlyingAsset.mint(alice, _amount);

    _deposit(underlyingAsset, vault, _amount, alice);
    vault.withdraw(_halfAmount, alice, alice);

    assertEq(vault.balanceOf(alice), _halfAmount);
    assertEq(underlyingAsset.balanceOf(alice), _halfAmount);

    assertEq(twabController.balanceOf(address(vault), alice), _halfAmount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _halfAmount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _halfAmount);
    assertEq(yieldVault.balanceOf(address(vault)), _halfAmount);

    vm.stopPrank();
  }

  function testWithdrawFullAmountYieldAccrued() external {
    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    vm.startPrank(alice);

    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    uint256 _yield = 10e18;
    _accrueYield(underlyingAsset, yieldVault, _yield);

    vm.startPrank(alice);

    vault.withdraw(vault.maxWithdraw(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(yieldVault.convertToAssets(yieldVault.balanceOf(address(vault))), _yield);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _yield);

    vm.stopPrank();
  }

  /* ============ Redeem ============ */
  function testRedeemFullAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    _deposit(underlyingAsset, vault, _amount, alice);
    vault.redeem(vault.maxRedeem(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);
    assertEq(yieldVault.balanceOf(address(vault)), 0);

    vm.stopPrank();
  }

  function testRedeemHalfAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    uint256 _halfAmount = _amount / 2;
    underlyingAsset.mint(alice, _amount);

    uint256 _shares = _deposit(underlyingAsset, vault, _amount, alice);
    vault.redeem(_shares / 2, alice, alice);

    assertEq(vault.balanceOf(alice), _halfAmount);
    assertEq(underlyingAsset.balanceOf(alice), _halfAmount);

    assertEq(twabController.balanceOf(address(vault), alice), _halfAmount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _halfAmount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _halfAmount);
    assertEq(yieldVault.balanceOf(address(vault)), _halfAmount);

    vm.stopPrank();
  }

  function testRedeemFullAmountYieldAccrued() external {
    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    vm.startPrank(alice);

    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    uint256 _yield = 10e18;
    _accrueYield(underlyingAsset, yieldVault, _yield);

    vm.startPrank(alice);

    vault.redeem(vault.maxRedeem(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(yieldVault.convertToAssets(yieldVault.balanceOf(address(vault))), _yield);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _yield);

    vm.stopPrank();
  }
}
