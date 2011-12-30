Feature: Column Mappings
  As a user
  I want to view a list of column mappings

  Background:
    Given I am logged in as "georgina@intersect.org.au"

  Scenario: View the list
    Given I have column mappings
      | name    | code | 
      | Sample  | smp  |
      | Average | avg  |
      | Count   | no.  |
    When I am on the column mappings page
    Then I should see "column_mappings" table with
      | Name    | Code | 
      | Average | avg  |
      | Count   | no.  | 
      | Sample  | smp  | 

  Scenario: View the list when there's nothing to show
    When I am on the column mappings page
    Then I should see "No column mappings to display."

  Scenario: Must be logged in to view the list
    Then users should be required to login on the column mappings page