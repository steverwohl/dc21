Feature: Delete files containing erroneous data
  In order to maintain the integrity of the data stored in the system
  As a user
  I want to remove my files that are invalid or that I have uploaded erroneously

  Background:
    And I am logged in as "georgina@intersect.org.au"

  Scenario: Deleting a file removes it from the list of files in Explore Data
    And I upload "toa5.dat" through the applet as "georgina@intersect.org.au"
    And I upload "weather_station_15_min.dat" through the applet as "georgina@intersect.org.au"
    Given I am on the list data files page
    And I should see only these rows in "exploredata" table
      | Filename                   | Added by                  |
      | weather_station_15_min.dat | georgina@intersect.org.au |
      | toa5.dat                   | georgina@intersect.org.au |
    When I delete the file "weather_station_15_min.dat" added by "georgina@intersect.org.au"
    And I am on the list data files page
    Then I should see only these rows in "exploredata" table
      | Filename | Added by                  |
      | toa5.dat | georgina@intersect.org.au |


  @wip
  Scenario: Deleting a file shows the change in recent activity


  Scenario: Deleting a file causes it to no longer appear in search results
    Given I have data files
      | filename      | created_at       | uploaded_by               | start_time           | end_time               |
      | datafile7.dat | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
      | datafile6.dat | 30/12/2011 10:15 | kali@intersect.org.au     | 1/6/2010 6:42:01 UTC | 11/6/2010 18:05:23 UTC |
    And I do a date search for data files with dates "2010-06-03" and "2010-06-10"
    And I follow "Filename"
    And I should see "exploredata" table with
      | Filename      | Date added       | Start time          | End time            |
      | datafile6.dat | 2011-12-30 10:15 | 2010-06-01  6:42:01 | 2010-06-11 18:05:23 |
      | datafile7.dat | 2011-11-30 10:15 | 2010-06-01  6:42:01 | 2010-06-10 18:05:23 |
    When I delete the file "datafile7.dat" added by "georgina@intersect.org.au"
    And I do a date search for data files with dates "2010-06-03" and "2010-06-10"
    And I follow "Filename"
    Then I should see "exploredata" table with
      | Filename      | Date added       | Start time          | End time            |
      | datafile6.dat | 2011-12-30 10:15 | 2010-06-01  6:42:01 | 2010-06-11 18:05:23 |

  Scenario: Files can be deleted from the details page
    Given I have data files
      | filename      | created_at       | uploaded_by               | start_time           | end_time               |
      | datafile.dat  | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
      | datafile1.dat | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
    And I am on the data file details page for datafile.dat
    And I follow "Delete"
    Then I should be on the list data files page
    And I should see "The file 'datafile.dat' was successfully removed"
    And I should see only these rows in "exploredata" table
      | Filename      | Added by                  |
      | datafile1.dat | georgina@intersect.org.au |


  Scenario: Normal cannot delete others' files because they don't have a link
    Given I have a user "researcher@intersect.org.au" with role "Researcher"
    And I logout
    And I am logged in as "researcher@intersect.org.au"
    And I have data files
      | filename     | created_at       | uploaded_by           | start_time           | end_time               |
      | datafile.dat | 30/11/2011 10:15 | kali@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
    And I am on the data file details page for datafile.dat
    Then I should not see link "Delete"

  @wip
  Scenario: Normal cannot delete others' files via less scrupulous means
    Given I have data files
      | filename     | created_at       | uploaded_by           | start_time           | end_time               |
      | datafile.dat | 30/11/2011 10:15 | kali@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
    And I visit the delete url for "datafile.dat"
    Then I should be on the list data files page
    And I should see "Could not delete this file (Do you have permission to delete it?)"

  Scenario: Super users can delete any file regardless of user
    Given I have data files
      | filename      | created_at       | uploaded_by           | start_time           | end_time               |
      | datafile.dat  | 30/11/2011 10:15 | kali@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
      | datafile1.dat | 30/11/2011 10:15 | kali@intersect.org.au | 1/6/2010 6:42:01 UTC | 10/6/2010 18:05:23 UTC |
    And I am on the data file details page for datafile.dat
    And I follow "Delete"
    Then I should be on the list data files page
    And I should see "The file 'datafile.dat' was successfully removed"
    And I should see only these rows in "exploredata" table
      | Filename      | Added by                  |
      | datafile1.dat | kali@intersect.org.au |