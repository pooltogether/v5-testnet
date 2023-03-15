Feature: Claimer
  Scenario: Alice claims a prize
    Given the draw has been awarded and Alice has won but has not claimed her prize yet
    When Alice claims her prize
    Then Alice must receive her prize minus the claim fee for the tier she claimed
    Then the PrizePool balance of prize token must decrease by the prize amount
    Then Alice can't claim her prize again
