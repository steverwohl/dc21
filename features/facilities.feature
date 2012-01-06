Feature: View the list of facilities
  As a user
  I want to view a list of facilties and be able to add/edit and view them

  Background:
    Given I am logged in as "georgina@intersect.org.au"

  Scenario: View the list
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
      | Facility1 | f1   | 
    When I am on the facilities page
    Then I should see "facilities" table with
      | Name      | Code |
      | Facility0 | f0   | 
      | Facility1 | f1   |

  Scenario: Facilities list should be ordered by name
    Given I have facilities
      | name      | code |
      | Facility2 | f2   |
      | Facility1 | f1   |
      | Facility4 | f4   |
      | Facility0 | f0   |
      | Facility3 | f3   |
    When I am on the facilities page
    Then I should see "facilities" table with
      | Name      | Code |
      | Facility0 | f0   | 
      | Facility1 | f1   |
      | Facility2 | f2   |
      | Facility3 | f3   |
      | Facility4 | f4   |

  Scenario: View the list when there's nothing to show
    When I am on the facilities page
    Then I should see "Displaying 0 of 0 Facilities"

  Scenario: Must be logged in to view the facilities list
    Then users should be required to login on the facilities page

  Scenario: View a facility
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    Then I should see details displayed
      | Name  | Facility0  |
      | Code  | f0         |

  Scenario: Navigate back to the list of facilities
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    And I follow "Back"
    Then I should be on the facilities page

  Scenario: Create a new facility
    Given I am on the facilities page
    And I follow "New Facility"
    When I fill in the following:
      | facility_name | Facility0 |
      | facility_code | f0        |
    And I press "Save Facility"
    Then I should see "Facility successfully added"
    And I should see details displayed
      | Name  | Facility0  |
      | Code  | f0         |

  Scenario: Create a new facility with invalid details
    Given I am on the facilities page
    And I follow "New Facility"
    When I fill in the following:
      | facility_name | |
      | facility_code | |
    And I press "Save Facility"
    Then I should see "Name can't be blank"
    And I should see "Code can't be blank"

  Scenario: Create a duplicate facility
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow "New Facility"
    When I fill in the following:
      | facility_name | Facility0 |
      | facility_code | f0        |
    And I press "Save Facility"
    Then I should see "Name has already been taken"
    Then I should see "Code has already been taken"

  Scenario: Navigate back to the list of facilities from create screen
    Given I am on the facilities page
    And I follow "New Facility"
    And I follow "Cancel"
    Then I should be on the facilities page

  Scenario: Edit the details of a facility
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    And I follow "Edit Facility"
    And I fill in the following:
      | facility_name | Facility1 |
      | facility_code | fac1      |
    And I press "Update"
    Then I should see "Facility successfully updated."
    And I should see details displayed
      | Name  | Facility1  |
      | Code  | fac1       |

  Scenario: Edit the details of a facility to something invalid
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    And I follow "Edit Facility"
    And I fill in the following:
      | facility_name | really_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_namereally_long_name|
      | facility_code | |
    And I press "Update"
    Then I should see "Code can't be blank"
    And I should see "Name is too long (maximum is 50 characters)"

  Scenario: Edit the details of a facility to become a duplicate
   Given I have facilities
      | name      | code |
      | Facility0 | f0   |
      | Facility1 | f1   |
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    And I follow "Edit Facility"
    And I fill in the following:
      | facility_name | Facility1 |
      | facility_code | f1        |
    And I press "Update"
    Then I should see "Name has already been taken"
    And I should see "Code has already been taken"

  Scenario: Cancelling the edit of a facility
     Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    And I follow "Edit Facility"
    And I fill in the following:
      | facility_name | Facility1 |
      | facility_code | f1        |
    And I follow "Cancel"
    Then I should see details displayed
      | Name  | Facility0  |
      | Code  | f0         |

  Scenario: Navigate back to the list of facilities from edit screen
    Given I have facilities
      | name      | code | 
      | Facility0 | f0   | 
    When I am on the facilities page
    And I follow the view link for facility "Facility0"
    And I follow "Edit Facility"
    And I follow "Cancel"
    Then I should see details displayed
      | Name  | Facility0  |
      | Code  | f0         |

