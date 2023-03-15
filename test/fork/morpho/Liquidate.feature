Feature: Liquidate
  Scenario: Alice swaps prize tokens (i.e. POOL) in exchange of Vault shares
    Given Underlying assets have accrued in the Vault
    When Alice swaps the equivalent amount of prize tokens for Vault shares through the LiquidationRouter
    Then Alice prize tokens are sent to the PrizePool
    Then Alice prize tokens balance decreases by the equivalent amount
    Then the prize tokens are contributed to the PrizePool
    Then the Vault mints the equivalent amount of shares to Alice
