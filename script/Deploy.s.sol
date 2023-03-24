// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";

import { PrizePool, SD59x18 } from "v5-prize-pool/PrizePool.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { TwabController } from "v5-twab-controller/TwabController.sol";
import { Claimer, IVault } from "v5-vrgda-claimer/Claimer.sol";
import { ILiquidationSource } from "v5-liquidator/interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "v5-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "v5-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "v5-liquidator/LiquidationRouter.sol";
import { UFixed32x9 } from "v5-liquidator-libraries/FixedMathLib.sol";

import { ERC20Mintable } from "src/ERC20Mintable.sol";
import { MarketRate } from "src/MarketRate.sol";
import { TokenFaucet } from "src/TokenFaucet.sol";
import { VaultMintRate } from "src/VaultMintRate.sol";
import { ERC20, YieldVaultMintRate } from "src/YieldVaultMintRate.sol";

contract Deploy is Script {
  uint8 internal constant DEFAULT_TOKEN_DECIMAL = 18;
  uint8 internal constant USDC_TOKEN_DECIMAL = 6;
  uint8 internal constant GUSD_TOKEN_DECIMAL = 2;
  uint8 internal constant WBTC_TOKEN_DECIMAL = 8;
  uint256 internal constant ONE_YEAR_IN_SECONDS = 31557600;

  uint256 internal constant PRIZE_TOKEN_PRICE = 1e18;

  uint32 internal drawPeriodSeconds = 2 hours;

  Claimer internal claimer;
  LiquidationPairFactory internal liquidationPairFactory;
  MarketRate internal marketRate;
  PrizePool internal prizePool;
  TokenFaucet internal tokenFaucet;
  TwabController internal twabController;

  ERC20Mintable internal prizeToken;

  function _toDecimals(uint256 _amount, uint8 _decimals) internal pure returns (uint256) {
    return _amount * (10 ** _decimals);
  }

  function _getRatePerSeconds(uint256 _rate) internal pure returns (uint256) {
    return _rate / ONE_YEAR_IN_SECONDS;
  }

  /**
   * @notice Get exchange rate for liquidation pair `virtualReserveOut`.
   * @param _tokenPrice Price of the token represented in 8 decimals
   * @param _decimalOffset Offset between the prize token decimals and the token decimals
   */
  function _getExchangeRate(
    uint256 _tokenPrice,
    uint8 _decimalOffset
  ) internal pure returns (uint128) {
    return uint128((PRIZE_TOKEN_PRICE * 1e8) / (_tokenPrice * (10 ** _decimalOffset)));
  }

  function _deployYieldVault(
    ERC20Mintable _underlyingAsset,
    string memory _nameSuffix,
    string memory _symbolSuffix
  ) internal returns (YieldVaultMintRate) {
    string memory _underlyingAssetName = _underlyingAsset.name();
    string memory _underlyingAssetSymbol = _underlyingAsset.symbol();

    return
      new YieldVaultMintRate(
        _underlyingAsset,
        string.concat("PoolTogether ", _underlyingAssetName, _nameSuffix, " Yield"),
        string.concat("PT", _underlyingAssetSymbol, _symbolSuffix, "Y"),
        msg.sender
      );
  }

  function _deployVault(
    YieldVaultMintRate _yieldVault,
    string memory _nameSuffix,
    string memory _symbolSuffix,
    uint128 _virtualReserveOut
  ) internal returns (VaultMintRate vault) {
    ERC20 _underlyingAsset = ERC20(_yieldVault.asset());
    string memory _underlyingAssetName = _underlyingAsset.name();
    string memory _underlyingAssetSymbol = _underlyingAsset.symbol();

    vault = new VaultMintRate(
      _underlyingAsset,
      string.concat("PoolTogether ", _underlyingAssetName, _nameSuffix, " Prize Token"),
      string.concat("PT", _underlyingAssetSymbol, _symbolSuffix, "T"),
      twabController,
      _yieldVault,
      prizePool,
      claimer,
      msg.sender
    );

    LiquidationPair liquidationPair = liquidationPairFactory.createPair(
      ILiquidationSource(vault),
      address(prizeToken),
      address(vault),
      UFixed32x9.wrap(0.3e9),
      UFixed32x9.wrap(0.02e9),
      1e18,
      _virtualReserveOut
    );

    vault.setLiquidationPair(liquidationPair);
  }

  function _tokenGrantMinterRole(ERC20Mintable _token, address _grantee) internal {
    _token.grantRole(_token.MINTER_ROLE(), _grantee);
  }

  function _vaultGrantMinterRole(YieldVaultMintRate _vault, address _grantee) internal {
    _vault.grantRole(_vault.MINTER_ROLE(), _grantee);
  }

  function _tokenGrantMinterRoles(ERC20Mintable _token) internal {
    _tokenGrantMinterRole(_token, address(0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A));
    _tokenGrantMinterRole(_token, address(0x5E6CC2397EcB33e6041C15360E17c777555A5E63));
    _tokenGrantMinterRole(_token, address(0xA57D294c3a11fB542D524062aE4C5100E0E373Ec));
    _tokenGrantMinterRole(_token, address(0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0));
  }

  function _vaultGrantMinterRoles(YieldVaultMintRate _vault) internal {
    _vaultGrantMinterRole(_vault, address(0x22f928063d7FA5a90f4fd7949bB0848aF7C79b0A));
    _vaultGrantMinterRole(_vault, address(0x5E6CC2397EcB33e6041C15360E17c777555A5E63));
    _vaultGrantMinterRole(_vault, address(0xA57D294c3a11fB542D524062aE4C5100E0E373Ec));
    _vaultGrantMinterRole(_vault, address(0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0));
  }

  function _deployStableVaults() internal {
    string memory _denominator = "USD";
    uint256 _mintAmount = 100_000_000;
    address _tokenFaucetAddress = address(tokenFaucet);

    /* DAI */
    ERC20Mintable dai = new ERC20Mintable(
      "Dai Stablecoin",
      "DAI",
      DEFAULT_TOKEN_DECIMAL,
      msg.sender
    );

    dai.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, DEFAULT_TOKEN_DECIMAL));

    uint256 daiPrice = 100000000;
    marketRate.setPrice(address(dai), _denominator, 100000000);

    YieldVaultMintRate daiLowYieldVault = _deployYieldVault(dai, "Low", "L");
    _tokenGrantMinterRole(dai, address(daiLowYieldVault));
    _tokenGrantMinterRoles(dai);
    _vaultGrantMinterRoles(daiLowYieldVault);

    daiLowYieldVault.setRatePerSecond(_getRatePerSeconds(6600000000000000)); // 0.66%
    _deployVault(daiLowYieldVault, " Low Yield", "LY", _getExchangeRate(daiPrice, 0));

    YieldVaultMintRate daiHighYieldVault = _deployYieldVault(dai, "High", "H");
    _tokenGrantMinterRole(dai, address(daiHighYieldVault));
    _vaultGrantMinterRoles(daiHighYieldVault);

    daiHighYieldVault.setRatePerSecond(_getRatePerSeconds(250000000000000000)); // 25%
    _deployVault(daiHighYieldVault, " High Yield", "HY", _getExchangeRate(daiPrice, 0));

    /* USDC */
    ERC20Mintable usdc = new ERC20Mintable("USD Coin", "USDC", USDC_TOKEN_DECIMAL, msg.sender);
    usdc.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, USDC_TOKEN_DECIMAL));

    uint256 usdcPrice = 100000000;
    marketRate.setPrice(address(usdc), _denominator, usdcPrice);

    YieldVaultMintRate usdcLowYieldVault = _deployYieldVault(usdc, "Low", "L");
    _tokenGrantMinterRole(usdc, address(usdcLowYieldVault));
    _tokenGrantMinterRoles(usdc);
    _vaultGrantMinterRoles(usdcLowYieldVault);

    usdcLowYieldVault.setRatePerSecond(_getRatePerSeconds(13300000000000000)); // 1.33%
    _deployVault(usdcLowYieldVault, " Low Yield", "LY", _getExchangeRate(usdcPrice, 12));

    YieldVaultMintRate usdcHighYieldVault = _deployYieldVault(usdc, "High", "H");
    _tokenGrantMinterRole(usdc, address(usdcHighYieldVault));
    _vaultGrantMinterRoles(usdcHighYieldVault);

    usdcHighYieldVault.setRatePerSecond(_getRatePerSeconds(500000000000000000)); // 50%
    _deployVault(usdcHighYieldVault, " High Yield", "HY", _getExchangeRate(usdcPrice, 12));

    /* gUSD */
    ERC20Mintable gUSD = new ERC20Mintable("Gemini dollar", "GUSD", GUSD_TOKEN_DECIMAL, msg.sender);
    gUSD.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, GUSD_TOKEN_DECIMAL));

    uint256 gUSDCPrice = 100000000;
    marketRate.setPrice(address(gUSD), _denominator, gUSDCPrice);

    YieldVaultMintRate gUSDYieldVault = _deployYieldVault(gUSD, "", "");
    _tokenGrantMinterRole(gUSD, address(gUSDYieldVault));
    _tokenGrantMinterRoles(gUSD);
    _vaultGrantMinterRoles(gUSDYieldVault);

    gUSDYieldVault.setRatePerSecond(_getRatePerSeconds(12700000000000000)); // 1.27%
    _deployVault(gUSDYieldVault, "", "", _getExchangeRate(gUSDCPrice, 16));
  }

  function _deployVaults() internal {
    string memory _denominator = "USD";
    uint256 _mintAmount = 100_000_000;
    address _tokenFaucetAddress = address(tokenFaucet);

    /* wBTC */
    ERC20Mintable wBTC = new ERC20Mintable("Wrapped BTC", "WBTC", WBTC_TOKEN_DECIMAL, msg.sender);
    wBTC.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, WBTC_TOKEN_DECIMAL));

    uint256 _wBTCPrice = 2488023943815;
    marketRate.setPrice(address(wBTC), _denominator, _wBTCPrice);

    YieldVaultMintRate wBTCYieldVault = _deployYieldVault(wBTC, "", "");
    _tokenGrantMinterRole(wBTC, address(wBTCYieldVault));
    _tokenGrantMinterRoles(wBTC);
    _vaultGrantMinterRoles(wBTCYieldVault);

    wBTCYieldVault.setRatePerSecond(_getRatePerSeconds(400000000000000)); // 0.04%
    _deployVault(wBTCYieldVault, "", "", _getExchangeRate(_wBTCPrice, 10));

    /* wETH */
    ERC20Mintable wETH = new ERC20Mintable(
      "Wrapped Ether",
      "WETH",
      DEFAULT_TOKEN_DECIMAL,
      msg.sender
    );

    wETH.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, DEFAULT_TOKEN_DECIMAL));

    uint256 _ethPrice = 166876925050;
    marketRate.setPrice(address(wETH), _denominator, _ethPrice);
    marketRate.setPrice(address(0), _denominator, _ethPrice);

    YieldVaultMintRate wETHYieldVault = _deployYieldVault(wETH, "", "");
    _tokenGrantMinterRole(wETH, address(wETHYieldVault));
    _tokenGrantMinterRoles(wETH);
    _vaultGrantMinterRoles(wETHYieldVault);

    wETHYieldVault.setRatePerSecond(_getRatePerSeconds(29300000000000000)); // 2.93%
    _deployVault(wETHYieldVault, "", "", _getExchangeRate(_ethPrice, 0));
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

    marketRate = new MarketRate(8, msg.sender);
    tokenFaucet = new TokenFaucet();
    twabController = new TwabController();

    prizeToken = new ERC20Mintable("PoolTogether", "POOL", DEFAULT_TOKEN_DECIMAL, msg.sender);
    _tokenGrantMinterRoles(prizeToken);

    prizeToken.mint(address(tokenFaucet), _toDecimals(10_000_000, DEFAULT_TOKEN_DECIMAL));
    marketRate.setPrice(address(prizeToken), "USD", 98000000);

    prizePool = new PrizePool(
      prizeToken,
      twabController,
      uint32(365), // 52 weeks = 1 year
      drawPeriodSeconds, // drawPeriodSeconds
      uint64(block.timestamp), // drawStartedAt
      uint8(2), // minimum number of tiers
      100e18,
      10e18,
      10e18,
      ud2x18(0.9e18), // claim threshold of 90%
      sd1x18(0.9e18) // alpha
    );

    claimer = new Claimer(prizePool, ud2x18(1.1e18), 0.0001e18);

    liquidationPairFactory = new LiquidationPairFactory();
    new LiquidationRouter(liquidationPairFactory);

    // Need two functions to avoid stack too deep error
    _deployStableVaults();
    _deployVaults();

    vm.stopBroadcast();
  }
}
