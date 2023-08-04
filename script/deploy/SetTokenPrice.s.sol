// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { MarketRate } from "../../src/MarketRate.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract SetTokenPrice is Helpers {
  function _setTokensPrice() internal {
    string memory _denominator = "USD";
    MarketRate marketRate = _getMarketRate();

    /* DAI */
    ERC20Mintable dai = _getToken("DAI", _stableTokenDeployPath);
    marketRate.setPrice(address(dai), _denominator, DAI_PRICE);

    /* USDC */
    ERC20Mintable usdc = _getToken("USDC", _stableTokenDeployPath);
    marketRate.setPrice(address(usdc), _denominator, USDC_PRICE);

    /* gUSD */
    ERC20Mintable gUSD = _getToken("GUSD", _stableTokenDeployPath);
    marketRate.setPrice(address(gUSD), _denominator, GUSD_PRICE);

    /* wBTC */
    ERC20Mintable wBTC = _getToken("WBTC", _tokenDeployPath);
    marketRate.setPrice(address(wBTC), _denominator, WBTC_PRICE);

    /* wETH */
    ERC20Mintable wETH = _getToken("WETH", _tokenDeployPath);
    marketRate.setPrice(address(wETH), _denominator, ETH_PRICE);
    marketRate.setPrice(address(0), _denominator, ETH_PRICE);

    /* prizeToken */
    ERC20Mintable prizeToken = _getToken("POOL", _tokenDeployPath);
    marketRate.setPrice(address(prizeToken), _denominator, POOL_PRICE);
  }

  function run() public {
    vm.startBroadcast();
    _setTokensPrice();
    vm.stopBroadcast();
  }
}
