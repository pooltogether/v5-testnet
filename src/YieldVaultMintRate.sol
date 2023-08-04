// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { AccessControl } from "openzeppelin/access/AccessControl.sol";
import { ERC20, ERC4626, IERC20, IERC20Metadata } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import { ERC20Mintable } from "src/ERC20Mintable.sol";

contract YieldVaultMintRate is ERC4626, AccessControl {
  /* ============ Variables ============ */

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public ratePerSecond;
  uint256 public lastYieldTimestamp;

  /* ============ Constructor ============ */

  constructor(
    ERC20Mintable _asset,
    string memory _name,
    string memory _symbol,
    address _owner
  ) ERC20(_name, _symbol) ERC4626(IERC20(_asset)) {
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(MINTER_ROLE, _owner);
  }

  /* ============ External Functions ============ */

  function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
    _mintRate();
    return super.deposit(assets, receiver);
  }

  function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
    _mintRate();
    return super.mint(shares, receiver);
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public virtual override returns (uint256) {
    _mintRate();
    return super.withdraw(assets, receiver, owner);
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public virtual override returns (uint256) {
    _mintRate();
    return super.redeem(shares, receiver, owner);
  }

  function setRatePerSecond(uint256 _ratePerSecond) external onlyMinterRole {
    _mintRate();
    lastYieldTimestamp = block.timestamp;
    ratePerSecond = _ratePerSecond;
  }

  function yield(uint256 amount) external onlyMinterRole {
    ERC20Mintable(asset()).mint(address(this), amount);
  }

  function mintRate() external onlyMinterRole {
    _mintRate();
  }

  /* ============ Internal Functions ============ */

  function _mintRate() internal {
    uint256 deltaTime = block.timestamp - lastYieldTimestamp;
    uint256 rateMultiplier = deltaTime * ratePerSecond;
    uint256 balance = ERC20Mintable(asset()).balanceOf(address(this));

    ERC20Mintable(asset()).mint(address(this), (rateMultiplier * balance) / 1 ether);
    lastYieldTimestamp = block.timestamp;
  }

  /* ============ Modifiers ============ */

  modifier onlyMinterRole() {
    require(hasRole(MINTER_ROLE, msg.sender), "YieldVault/caller-not-minter");
    _;
  }
}
