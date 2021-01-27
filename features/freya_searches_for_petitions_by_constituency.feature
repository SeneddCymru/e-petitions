Feature: Freya searches petitions by constituency
  In order to see what petitions are relevant to other people in my constituency
  As Freya, a member of the general public
  I want to use my postcode to find my constituency and see petitions with signatures from people who also live in it

  Background:
    Given a constituency "Kirkcaldy" with Member "David Torrance MSP" is found by postcode "KY1 1HX"
    And a constituency "Stirling" is found by postcode "FK17 8HJ"
    And an open petition "Save the monkeys" with some signatures
    And an open petition "Restore vintage diggers" with some signatures
    And an open petition "Build more quirky theme parks" with some signatures
    And a closed petition "What about other primates?" with some signatures
    And a constituent in "Stirling" supports "Restore vintage diggers"
    And few constituents in "Kirkcaldy" support "Save the monkeys"
    And some constituents in "Kirkcaldy" support "Build more quirky theme parks"
    And many constituents in "Stirling" support "Build more quirky theme parks"
    And a constituent in "Kirkcaldy" supports "What about other primates?"

  Scenario: Searching for local petitions
    Given I am on the home page
    When I search for petitions local to me in "KY1 1HX"
    Then I should be on the local petitions results page
    And the markup should be valid
    And I should see "Petitions in Kirkcaldy" in the browser page title
    And I should see "Popular open petitions in the constituency of Kirkcaldy"
    And I should see a link to view all local petitions
    And I should see a link to the Member for my constituency
    And I should see that my fellow constituents support "Save the monkeys"
    And I should see that my fellow constituents support "Build more quirky theme parks"
    But I should not see that my fellow constituents support "What about other primates?"
    And I should not see that my fellow constituents support "Restore vintage diggers"
    And the petitions I see should be ordered by my fellow constituents level of support
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    And I should see "Popular petitions in the constituency of Kirkcaldy"
    And I should see a link to view open local petitions
    And I should see that my fellow constituents support "What about other primates?"
    And I should see that closed petitions are identified
    And the petitions I see should be ordered by my fellow constituents level of support

  Scenario: Downloading the JSON data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "KY1 1HX"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "KY1 1HX"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "KY1 1HX"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-kirkcaldy.csv"

  Scenario: Downloading the CSV data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "KY1 1HX"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-kirkcaldy.csv"

  Scenario: Searching for local petitions when the no-one in my constituency is engaged
    Given a constituency "Linlithgow" is found by postcode "EH28 8YQ"
    And I am on the home page
    When I search for petitions local to me in "EH28 8YQ"
    Then the markup should be valid
    But I should see an explanation that there are no petitions popular in my constituency

  Scenario: Searching for local petitions when the member has passed away
    Given a constituency "Rutherglen" with Member "Harry Harpham MSP" is found by postcode "G72 0EN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "G72 0EN"
    Then the markup should be valid
    And I should not see a link to the Member for my constituency

  Scenario: Downloading the JSON data for open local petitions when the member has passed away
    Given a constituency "Rutherglen" with Member "Harry Harpham MSP" is found by postcode "G72 0EN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "G72 0EN"
    Then the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions when the member has passed away
    Given a constituency "Rutherglen" with Member "Harry Harpham MSP" is found by postcode "G72 0EN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "G72 0EN"
    Then the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for local petitions when the member has passed away
    Given a constituency "Rutherglen" with Member "Harry Harpham MSP" is found by postcode "G72 0EN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "G72 0EN"
    Then the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-rutherglen.csv"

  Scenario: Downloading the CSV data for local petitions when the member has passed away
    Given a constituency "Rutherglen" with Member "Harry Harpham MSP" is found by postcode "G72 0EN"
    And the Member has passed away
    When I am on the home page
    And I search for petitions local to me in "G72 0EN"
    Then the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-rutherglen.csv"
