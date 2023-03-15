// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";

import { IntegrationBaseSetup } from "test/utils/IntegrationBaseSetup.t.sol";
import { Helpers } from "test/utils/Helpers.t.sol";

contract DepositIntegrationTest is IntegrationBaseSetup, Helpers {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Tests ============ */
  function testDeposit() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    _deposit(underlyingAsset, vault, _amount, alice);

    assertEq(vault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _amount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);
    assertEq(yieldVault.balanceOf(address(vault)), _amount);

    vm.stopPrank();
  }

  function testSponsor() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    _sponsor(underlyingAsset, vault, _amount, alice);

    assertEq(vault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(vault.balanceOf(SPONSORSHIP_ADDRESS), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), SPONSORSHIP_ADDRESS), 0);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);
    assertEq(yieldVault.balanceOf(address(vault)), _amount);

    vm.stopPrank();
  }

  function testDelegate() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    _deposit(underlyingAsset, vault, _amount, alice);

    twabController.delegate(address(vault), bob);

    assertEq(vault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(vault.balanceOf(bob), 0);

    assertEq(twabController.balanceOf(address(vault), bob), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), bob), _amount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);
    assertEq(yieldVault.balanceOf(address(vault)), _amount);

    vm.stopPrank();
  }
}
