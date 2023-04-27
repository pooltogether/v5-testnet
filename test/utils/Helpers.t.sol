// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { ERC20Mock } from "openzeppelin/mocks/ERC20Mock.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import { Claim, Claimer, IVault } from "v5-vrgda-claimer/Claimer.sol";
import { PrizePool } from "v5-prize-pool/PrizePool.sol";
import { LiquidationPair } from "v5-liquidator/LiquidationPair.sol";
import { LiquidationRouter } from "v5-liquidator/LiquidationRouter.sol";
import { Vault } from "v5-vault/Vault.sol";
import { YieldVault } from "v5-vault-mock/YieldVault.sol";

contract Helpers is Test {
  /* ============ Deposit ============ */
  function _deposit(
    IERC20 _underlyingAsset,
    IERC4626 _vault,
    uint256 _amount,
    address _user
  ) internal returns (uint256) {
    _underlyingAsset.approve(address(_vault), type(uint256).max);
    return _vault.deposit(_amount, _user);
  }

  function _sponsor(
    IERC20 _underlyingAsset,
    Vault _vault,
    uint256 _amount,
    address _user
  ) internal returns (uint256) {
    _underlyingAsset.approve(address(_vault), type(uint256).max);
    return _vault.sponsor(_amount, _user);
  }

  /* ============ Liquidate ============ */
  function _accrueYield(ERC20Mock _underlyingAsset, IERC4626 _yieldVault, uint256 _yield) internal {
    _underlyingAsset.mint(address(_yieldVault), _yield);
  }

  function _liquidate(
    LiquidationRouter _liquidationRouter,
    LiquidationPair _liquidationPair,
    IERC20 _prizeToken,
    uint256 _yield,
    address _user
  ) internal returns (uint256 userPrizeTokenBalanceBeforeSwap, uint256 prizeTokenContributed) {
    maxPrizeTokenContributed = _liquidationPair.computeExactAmountIn(_yield);
    uint256 vaultShares = _liquidationPair.computeExactAmountOut(prizeTokenContributed);
    console2.log("prizeTokenContributed", prizeTokenContributed);
    console2.log("vaultShares", vaultShares);

    _prizeToken.approve(address(_liquidationRouter), prizeTokenContributed);

    userPrizeTokenBalanceBeforeSwap = _prizeToken.balanceOf(_user);

    prizeTokenContributed = _liquidationRouter.swapExactAmountOut(
      _liquidationPair,
      _user,
      _yield,
      maxPrizeTokenContributed
    );
  }

  /* ============ Award ============ */
  function _award(PrizePool _prizePool, uint256 _winningRandomNumber) internal {
    vm.warp(_prizePool.nextDrawStartsAt() + _prizePool.drawPeriodSeconds());
    _prizePool.completeAndStartNextDraw(_winningRandomNumber);
  }

  /* ============ Claim ============ */
  function _claim(
    Claimer _claimer,
    Vault _vault,
    PrizePool _prizePool,
    address _user,
    uint8[] memory _tiers
  ) internal returns (uint256) {
    Claim[] memory claims = new Claim[](1);
    claims[0] = Claim({ vault: IVault(address(_vault)), winner: _user, tier: _tiers[0] });

    uint32 _drawPeriodSeconds = _prizePool.drawPeriodSeconds();

    vm.warp(
      _drawPeriodSeconds /
        _prizePool.estimatedPrizeCount() +
        _prizePool.lastCompletedDrawStartedAt() +
        _drawPeriodSeconds +
        10
    );

    (, uint256 _totalFees) = _claimer.claimPrizes(0, claims, address(this));

    return _totalFees;
  }
}
