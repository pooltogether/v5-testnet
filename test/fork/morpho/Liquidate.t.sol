// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { ERC20Mock, IERC20 } from "openzeppelin/mocks/ERC20Mock.sol";
import { IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import { ForkBaseSetup } from "test/utils/ForkBaseSetup.t.sol";
import { Helpers } from "test/utils/Helpers.t.sol";

contract LiquidateMorphoForkTest is ForkBaseSetup, Helpers {
  uint256 public mainnetFork;
  uint256 public startBlock = 16_778_280;

  IERC4626 public yieldVault;
  IERC20 public aToken;
  IERC20 public maToken;
  IERC20 public variableDebtToken;
  address public morphoPoolAddress;

  /* ============ setUp ============ */
  function setUp() public {
    mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), startBlock);
    vm.selectFork(mainnetFork);

    address morphoVaultAddress = 0xA5269A8e31B93Ff27B887B56720A25F844db0529; // Morpho - Aave V2 USDC Vault on Mainnet
    address aTokenAddress = 0xBcca60bB61934080951369a648Fb03DF4F96263C; // Aave - aUSDC token on Mainnet

    yieldVault = IERC4626(morphoVaultAddress);
    maToken = IERC20(morphoVaultAddress); // Morpho - maUSDC token on Mainnet
    variableDebtToken = IERC20(address(0x619beb58998eD2278e08620f97007e1116D5D25b)); // Aave - USDC VariableDebtToken on Mainnet
    aToken = IERC20(aTokenAddress);
    morphoPoolAddress = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0; // Morpho Pool on Mainnet

    vm.makePersistent(morphoVaultAddress);
    vm.makePersistent(morphoPoolAddress);
    vm.makePersistent(aTokenAddress);

    forkSetUp(yieldVault);
  }

  /* ============ Tests ============ */
  function testLiquidate() external {
    uint256 _amount = 10_000_000e6;
    deal(underlyingAssetAddress, address(this), _amount);

    uint256 _shares = _deposit(underlyingAsset, vault, _amount, address(this));

    uint256 _vaultBalanceBefore = yieldVault.convertToAssets(yieldVault.balanceOf(address(vault)));
    // uint256 _vaultBalanceBefore = vault.convertToAssets(vault.balanceOf(address(address(this))));
    console2.log("_vaultBalanceBefore", _vaultBalanceBefore);

    uint256 _aTokenBalanceBefore = aToken.balanceOf(morphoPoolAddress);
    console2.log("_aTokenBalanceBefore", _aTokenBalanceBefore);

    console2.log("block.number before", block.number);
    utils.mineBlocks(drawPeriodSeconds / 12); // Assuming 1 block every 12 seconds
    console2.log("block.number after", block.number);

    /**
     * TODO: finish writing test, the Vault deposit is not accumulating yield.
     * Looking at the doc, it seems that Morpho tokens are not interest bearing ones.
     * https://docs.morpho.xyz/start-here/faq#is-there-an-interest-bearing-token-ibtoken
     */
    uint256 _vaultBalanceAfter = yieldVault.convertToAssets(yieldVault.balanceOf(address(vault)));
    // uint256 _vaultBalanceAfter = vault.convertToAssets(vault.balanceOf(address(this)));
    console2.log("_vaultBalanceAfter", _vaultBalanceAfter);

    uint256 _aTokenBalanceAfter = aToken.balanceOf(morphoPoolAddress);
    console2.log("_aTokenBalanceAfter", _aTokenBalanceAfter);
  }
}
