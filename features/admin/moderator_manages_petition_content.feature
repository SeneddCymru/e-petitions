@admin
Feature: Moderator manages the Gaelic content of a petition

  Scenario: Copying the Gaelic content in the English fields to the Gaelic fields
    Given the Gaelic website is disabled
    And an open, untranslated petition exists with action: "Raise benefits", background: "They're too low"
    And I am logged in as a moderator
    When I view all petitions
    And I follow "Raise benefits"
    Then I press "Copy content to Gaelic petition"
    Then I should see "The petition's content has been copied over to the Gaelic version"
    And the petition content should be copied over

  Scenario: Clearing the content of the Gaelic fields
    Given the Gaelic website is disabled
    And an open, translated petition exists with action: "Raise benefits", background: "They're too low"
    And I am logged in as a moderator
    When I view all petitions
    And I follow "Raise benefits"
    Then I press "Remove Gaelic petition content"
    Then I should see "The Gaelic version of the petition's content has been reset"
    And the petition content should be reset
