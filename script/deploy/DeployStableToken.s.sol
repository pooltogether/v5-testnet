// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { ERC20Mintable } from "src/ERC20Mintable.sol";
import { MarketRate } from "src/MarketRate.sol";
import { TokenFaucet } from "src/TokenFaucet.sol";

import { Helpers } from "script/helpers/Helpers.sol";

contract DeployStableToken is Helpers {
  function _deployTokens() internal {
    uint256 _mintAmount = 100_000_000;

    new MarketRate(8, msg.sender);

    TokenFaucet tokenFaucet = new TokenFaucet();
    address _tokenFaucetAddress = address(tokenFaucet);

    /* DAI */
    ERC20Mintable dai = new ERC20Mintable(
      "Dai Stablecoin",
      "DAI",
      DEFAULT_TOKEN_DECIMAL,
      msg.sender
    );

    dai.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, DEFAULT_TOKEN_DECIMAL));

    /* USDC */
    ERC20Mintable usdc = new ERC20Mintable("USD Coin", "USDC", USDC_TOKEN_DECIMAL, msg.sender);
    usdc.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, USDC_TOKEN_DECIMAL));

    /* gUSD */
    ERC20Mintable gUSD = new ERC20Mintable("Gemini dollar", "GUSD", GUSD_TOKEN_DECIMAL, msg.sender);
    gUSD.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, GUSD_TOKEN_DECIMAL));
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    _deployTokens();
    vm.stopBroadcast();
  }
}
