// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { AccessControl } from "openzeppelin/access/AccessControl.sol";
import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the admin and the only minter.
 */
contract MarketRate is AccessControl {
  /* ============ Variables ============ */

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint8 internal _decimals;

  /* ============ Mappings ============ */

  /// token => denominator => price
  mapping(address => mapping(string => uint256)) public priceFeed;

  /* ============ Constructor ============ */

  constructor(uint8 decimals_, address _owner) {
    _decimals = decimals_;

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(MINTER_ROLE, _owner);
  }

  /* ============ External Functions ============ */

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function getPrice(address _token, string memory _denominator) public view returns (uint256) {
    return priceFeed[_token][_denominator];
  }

  function setPrice(
    address _token,
    string memory _denominator,
    uint256 _price
  ) external onlyMinterRole {
    _setPrice(_token, _denominator, _price);
  }

  function setPriceBatch(
    address[] calldata _tokens,
    string memory _denominator,
    uint256[] calldata _prices
  ) external onlyMinterRole {
    uint256 _tokensLength = _tokens.length;
    require(_tokensLength == _prices.length, "MarketRate/array-length-mismatch");

    for (uint256 i = 0; i < _tokensLength; i++) {
      _setPrice(_tokens[i], _denominator, _prices[i]);
    }
  }

  /* ============ Internal Functions ============ */
  function _setPrice(address _token, string memory _denominator, uint256 _price) private {
    priceFeed[_token][_denominator] = _price;
  }

  /* ============ Modifiers ============ */

  modifier onlyAdminRole() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "YieldVault/caller-not-admin");
    _;
  }

  modifier onlyMinterRole() {
    require(hasRole(MINTER_ROLE, msg.sender), "YieldVault/caller-not-minter");
    _;
  }
}
