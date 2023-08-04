// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { ERC20Mintable } from "../../src/ERC20Mintable.sol";
import { TokenFaucet } from "../../src/TokenFaucet.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract DeployToken is Helpers {
  function _deployTokens() internal {
    uint256 _mintAmount = 100_000_000;
    address _tokenFaucetAddress = address(_getTokenFaucet());

    /* wBTC */
    ERC20Mintable wBTC = new ERC20Mintable("Wrapped BTC", "WBTC", WBTC_TOKEN_DECIMAL, msg.sender);
    wBTC.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, WBTC_TOKEN_DECIMAL));

    /* wETH */
    ERC20Mintable wETH = new ERC20Mintable(
      "Wrapped Ether",
      "WETH",
      DEFAULT_TOKEN_DECIMAL,
      msg.sender
    );

    wETH.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, DEFAULT_TOKEN_DECIMAL));

    ERC20Mintable prizeToken = new ERC20Mintable(
      "PoolTogether",
      "POOL",
      DEFAULT_TOKEN_DECIMAL,
      msg.sender
    );

    prizeToken.mint(_tokenFaucetAddress, _toDecimals(_mintAmount, DEFAULT_TOKEN_DECIMAL));
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    _deployTokens();
    vm.stopBroadcast();
  }
}
