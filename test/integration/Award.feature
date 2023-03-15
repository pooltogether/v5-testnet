Feature: Award
  Scenario: The PrizePool is awarded at the end of the prize period
    Given the Vaults have contributed prize token to the PrizePool and the prize period has ended
    When the PrizePool is awarded
    Then the reserve
