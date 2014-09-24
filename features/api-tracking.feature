@api
Feature: Track certificate generation campaigns

  Scenario: Apply campaign tags to certificate generator
    Given I want to create a certificate via the API
    And I apply a campaign "brian"
    And I request a certificate via the API
    Then my certificate should be linked to a campaign
    And that campaign should be called "brian"

  Scenario: Don't link to campaign if no campaign specified
    Given I want to create a certificate via the API
    And I request a certificate via the API
    Then my certificate should not be linked to a campaign

  Scenario: Link multiple requests with the same name to the same campaign
    Given I request 2 certifcates with the campaign "fred"
    Then there should be one campaign
    And that campaign should have 2 certificate generators