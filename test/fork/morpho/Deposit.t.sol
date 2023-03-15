// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";
import { IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import { ForkBaseSetup } from "test/utils/ForkBaseSetup.t.sol";
import { Helpers } from "test/utils/Helpers.t.sol";

contract DepositMorphoForkTest is ForkBaseSetup, Helpers {
  IERC4626 public yieldVault;
  IERC20 public aToken;
  IERC20 public variableDebtToken;
  address public morphoPoolAddress;

  /* ============ setUp ============ */
  function setUp() public {
    uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
    vm.selectFork(mainnetFork);

    yieldVault = IERC4626(0xA5269A8e31B93Ff27B887B56720A25F844db0529); // Morpho - Aave V2 USDC Vault on Ethereum
    variableDebtToken = IERC20(address(0x619beb58998eD2278e08620f97007e1116D5D25b)); // Aave - USDC VariableDebtToken on Ethereum
    aToken = IERC20(address(0xBcca60bB61934080951369a648Fb03DF4F96263C)); // aUSDC token on Ethereum
    morphoPoolAddress = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0; // Morpho Pool on Ethereum

    forkSetUp(yieldVault);
  }

  /* ============ Tests ============ */
  function testDeposit() external {
    uint256 _amount = 1000e6;
    deal(underlyingAssetAddress, alice, _amount);

    vm.startPrank(alice);

    uint256 _aTokenBalanceBefore = aToken.balanceOf(morphoPoolAddress);
    uint256 _variableDebtTokenBalanceBefore = variableDebtToken.balanceOf(morphoPoolAddress);
    uint256 _shares = _deposit(underlyingAsset, vault, _amount, alice);

    assertEq(vault.balanceOf(alice), _shares);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _amount);

    if (_variableDebtTokenBalanceBefore < _amount) {
      assertApproxEqAbs(aToken.balanceOf(morphoPoolAddress), _aTokenBalanceBefore + _amount, 1);
    } else {
      // Part of the USDC variable debt is repayed
      assertEq(
        variableDebtToken.balanceOf(morphoPoolAddress),
        _variableDebtTokenBalanceBefore - _amount
      );
    }

    // The YieldVault may round down and mint a bit less shares
    assertApproxEqAbs(yieldVault.convertToAssets(yieldVault.balanceOf(address(vault))), _amount, 1);

    vm.stopPrank();
  }

  function testSponsor() external {
    uint256 _amount = 1000e6;
    deal(underlyingAssetAddress, alice, _amount);

    vm.startPrank(alice);

    uint256 _aTokenBalanceBefore = aToken.balanceOf(morphoPoolAddress);
    uint256 _variableDebtTokenBalanceBefore = variableDebtToken.balanceOf(morphoPoolAddress);
    uint256 _shares = _sponsor(underlyingAsset, vault, _amount, alice);

    assertEq(vault.balanceOf(alice), _shares);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(vault.balanceOf(SPONSORSHIP_ADDRESS), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), SPONSORSHIP_ADDRESS), 0);

    if (_variableDebtTokenBalanceBefore < _amount) {
      assertApproxEqAbs(aToken.balanceOf(morphoPoolAddress), _aTokenBalanceBefore + _amount, 1);
    } else {
      // Part of the USDC variable debt is repayed
      assertEq(
        variableDebtToken.balanceOf(morphoPoolAddress),
        _variableDebtTokenBalanceBefore - _amount
      );
    }

    // The YieldVault may round down and mint a bit less shares
    assertApproxEqAbs(yieldVault.convertToAssets(yieldVault.balanceOf(address(vault))), _amount, 1);

    vm.stopPrank();
  }

  function testDelegate() external {
    uint256 _amount = 1000e6;
    deal(underlyingAssetAddress, alice, _amount);

    vm.startPrank(alice);

    uint256 _aTokenBalanceBefore = aToken.balanceOf(morphoPoolAddress);
    uint256 _variableDebtTokenBalanceBefore = variableDebtToken.balanceOf(morphoPoolAddress);
    uint256 _shares = _deposit(underlyingAsset, vault, _amount, alice);

    twabController.delegate(address(vault), bob);

    assertEq(vault.balanceOf(alice), _shares);
    assertEq(vault.convertToAssets(vault.balanceOf(alice)), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), _amount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(twabController.balanceOf(address(vault), bob), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), bob), _amount);

    if (_variableDebtTokenBalanceBefore < _amount) {
      assertApproxEqAbs(aToken.balanceOf(morphoPoolAddress), _aTokenBalanceBefore + _amount, 1);
    } else {
      // Part of the USDC variable debt is repayed
      assertEq(
        variableDebtToken.balanceOf(morphoPoolAddress),
        _variableDebtTokenBalanceBefore - _amount
      );
    }

    // The YieldVault may round down and mint a bit less shares
    assertApproxEqAbs(yieldVault.convertToAssets(yieldVault.balanceOf(address(vault))), _amount, 1);

    vm.stopPrank();
  }
}
