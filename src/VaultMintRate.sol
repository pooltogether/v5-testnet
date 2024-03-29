// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { IERC4626, IERC20 } from "openzeppelin/mocks/ERC4626Mock.sol";

import { Claimer } from "v5-vrgda-claimer/Claimer.sol";
import { PrizePool } from "v5-prize-pool/PrizePool.sol";
import { Vault } from "v5-vault/Vault.sol";
import { TwabController } from "v5-twab-controller/TwabController.sol";

import { YieldVaultMintRate } from "src/YieldVaultMintRate.sol";

contract VaultMintRate is Vault {
  constructor(
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    TwabController _twabController,
    IERC4626 _yieldVault,
    PrizePool _prizePool,
    Claimer _claimer,
    address _yieldFeeRecipient,
    uint256 _yieldFeePercentage,
    address _owner
  )
    Vault(
      _asset,
      _name,
      _symbol,
      _twabController,
      _yieldVault,
      _prizePool,
      _claimer,
      _yieldFeeRecipient,
      _yieldFeePercentage,
      _owner
    )
  {}

  function liquidate(
    address _account,
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    uint256 _amountOut
  ) public override returns (bool) {
    YieldVaultMintRate(yieldVault()).mintRate(); // Updates the accrued yield in the YieldVaultMintRate
    return super.liquidate(_account, _tokenIn, _amountIn, _tokenOut, _amountOut);
  }
}
