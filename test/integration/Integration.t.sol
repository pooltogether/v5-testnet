// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ERC20Mock, IERC20Metadata } from "openzeppelin/mocks/ERC20Mock.sol";

import { BaseSetup, IVault } from "test/utils/BaseSetup.t.sol";

contract IntegrationTest is BaseSetup {
  /* ============ setUp ============ */
  function setUp() public override {
    super.setUp();
  }

  /* ============ Helper Functions ============ */
  function _accrueYield(uint256 _yield) internal {
    underlyingAsset.mint(address(this), _yield);

    underlyingAsset.approve(address(vault), _yield);
    vault.deposit(_yield, SPONSORSHIP_ADDRESS);

    underlyingAsset.mint(address(yieldVault), _yield);
  }

  function _liquidate(uint256 _yield) internal returns (uint256) {
    uint256 _prizeTokenToContribute = liquidationPair.computeExactAmountIn(_yield);

    prizeToken.mint(address(this), _prizeTokenToContribute);
    prizeToken.approve(address(liquidationRouter), _prizeTokenToContribute);

    liquidationRouter.swapExactAmountOut(
      liquidationPair,
      address(this),
      _yield,
      _prizeTokenToContribute
    );

    return _prizeTokenToContribute;
  }

  function _awardPrizePool() internal {
    // twabController.getAverageBalanceBetween(address(vault), address(this), uint32(1), uint32(86401));
    console2.log("prizePool.nextDrawStartsAt()", prizePool.nextDrawStartsAt());
    vm.warp(prizePool.nextDrawStartsAt() + drawPeriodSeconds);
    prizePool.completeAndStartNextDraw(winningRandomNumber);
  }

  function _claimPrizes() internal returns (uint256) {
    address[] memory _winners = new address[](1);
    _winners[0] = address(this);

    uint8[] memory _tiers = new uint8[](1);
    _tiers[0] = uint8(1);

    vm.warp(
      drawPeriodSeconds /
        prizePool.estimatedPrizeCount() +
        prizePool.lastCompletedDrawStartedAt() +
        drawPeriodSeconds +
        10
    );
    return claimer.claimPrizes(IVault(address(vault)), _winners, _tiers, 0, address(this));
  }

  /* ============ Tests ============ */
  function testLiquidate() external {
    uint256 _yield = 10e18;

    _accrueYield(_yield);
    uint256 _prizeTokenContributed = _liquidate(_yield);
    console2.log("_prizeTokenContributed", _prizeTokenContributed);

    assertEq(prizeToken.balanceOf(address(prizePool)), _prizeTokenContributed);
  }

  function testAwardPrizePool() external {
    uint256 _amount = 1000e18;
    uint256 _yield = 10e18;

    _deposit(_amount, address(this));

    _accrueYield(_yield);
    _liquidate(_yield);

    _awardPrizePool();

    assertEq(prizePool.reserve(), 1e18);
  }

  function testClaimPrizes() external {
    uint256 _amount = 1000e18;
    uint256 _yield = 10e18;

    _deposit(_amount, address(this));

    _accrueYield(_yield);
    _liquidate(_yield);

    _awardPrizePool();

    _claimPrizes();

    // assertEq(prizeToken.balanceOf(address(this)));
  }
}
