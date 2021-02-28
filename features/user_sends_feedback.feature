Feature: User sends feedback
  In order to see the site improved with my suggestions
  As a user of the site
  I want to be able to easily send feedback to the site owners

  Scenario:
    Given I am on the feedback page
    Then I should be able to submit feedback
    And the site owners should be notified

  Scenario: User must supply fields
    Given I am on the feedback page
    Then I cannot submit feedback without filling in the required fields

  @allow-rescue
  Scenario: Feedback page is disabled
    Given the feedback page is disabled
    And I am on the feedback page
    Then I will see 404 error page
