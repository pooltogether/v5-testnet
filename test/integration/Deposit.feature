Feature: Deposit
  Scenario: Alice deposits into the Vault
    Given Alice owns 0 Vault shares
    When Alice deposit 1,000 underlying assets
    Then Alice must receive an amount of Vault shares equivalent to her deposit
    Then Alice `balance` should be equal to the amount of underlying assets deposited
    Then Alice `delegateBalance` should be equal to the amount of underlying assets deposited
    Then The YieldVault balance of underlying assets must increase by the same amount deposited
    Then The YieldVault must mint to the Vault an amount of shares equivalent to the amount of underlying assets deposited

  Scenario: Alice sponsor the Vault
    Given Alice owns 0 Vault shares and has not sponsored the Vault
    When Alice sponsor by depositing 1,000 underlying assets
    Then Alice must receive an amount of Vault shares equivalent to her deposit
    Then Alice `balance` should be equal to the amount of underlying assets deposited
    Then Alice `delegateBalance` should be equal to 0
    Then The `balance` of the sponsoship address must be 0
    Then The `delegateBalance` of the sponsoship address must be 0
    Then The YieldVault balance of underlying assets must increase by the same amount deposited
    Then The YieldVault must mint to the Vault an amount of shares equivalent to the amount of underlying assets deposited

  Scenario: Alice delegates to Bob
    Given Alice and Bob owns 0 Vault shares and have not delegated to another address
    When Alice deposits 1,000 underlying assets and delegates to Bob
    Then Alice `balance` should be equal to the amount of underlying assets deposited
    Then Alice `delegateBalance` should be equal to 0
    Then Bob `balance` must be equal to 0
    Then Bob `delegateBalance` must be equal to the amount of underlying assets deposited by Alice
    Then The YieldVault balance of underlying assets must increase by the same amount deposited
    Then The YieldVault must mint to the Vault an amount of shares equivalent to the amount of underlying assets deposited
