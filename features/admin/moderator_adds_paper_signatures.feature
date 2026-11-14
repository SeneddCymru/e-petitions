@admin
Feature: Moderator adds paper signatures to a petition

  Scenario: Adding paper signatures to a petition
    Given an open petition "More money for charities" with some signatures
    And I am logged in as a moderator
    When I view all petitions
    And I follow "More money for charities"
    Then I should see "Paper signatures 0"
    When I follow "Add paper signatures"
    Then the "Location" field should contain "GB-WLS"
    When I press "Add signatures"
    Then I should see "Number of signatures must be completed"
    When I fill in "Number of signatures" with "0"
    And I press "Add signatures"
    Then I should see "Number of signatures must be greater than zero"
    When I fill in "Number of signatures" with "1.5"
    And I press "Add signatures"
    Then I should see "Number of signatures must be a whole number"
    When I select "England" from "Location"
    And I fill in "Number of signatures" with "3"
    And I press "Add signatures"
    Then I should see "Paper signatures are being added to the petition - this may take a few minutes"
    And 3 validated paper signatures should exist with location_code: "GB-ENG"
    And I should see "Paper signatures 3"
