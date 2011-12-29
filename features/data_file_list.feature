Feature: View the list of data files
  In order to find what I need
  As a user
  I want to view a list of data files

  Background:
    Given I am logged in as "georgina@intersect.org.au"

  Scenario: View the list
    Given I have data files
      | filename     | created_at       | uploaded_by               | start_time           | end_time                |
      | datafile.dat | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 UTC | 30/11/2011 18:05:23 UTC |
      | sample.txt   | 01/12/2011 13:45 | sean@intersect.org.au     |                      |                         |
    When I am on the list data files page
    Then I should see "exploredata" table with
      | Filename     | Date added       | Added by                  | Start time          | End time            |
      | sample.txt   | 2011-12-01 13:45 | sean@intersect.org.au     |                     |                     |
      | datafile.dat | 2011-11-30 10:15 | georgina@intersect.org.au | 2010-06-01  6:42:01 | 2011-11-30 18:05:23 |

  Scenario: View the list when there's nothing to show
    When I am on the list data files page
    Then I should see "No files to display."

  Scenario: Must be logged in to view the list
    Then users should be required to login on the list data files page

  Scenario: Sort the list of files by ascending start time
    Given I have data files
      | filename     | created_at       | uploaded_by               | start_time           | end_time                |
      | datafile.dat | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 UTC | 30/11/2011 18:05:23 UTC |
      | sample.txt   | 01/12/2011 13:45 | sean@intersect.org.au     |                      |                         |
    When I am on the list data files page
    When I follow "Date added"
    Then I should see "exploredata" table with
      | Filename     | Date added       | Added by                  | Start time          | End time            |
      | datafile.dat | 2011-11-30 10:15 | georgina@intersect.org.au | 2010-06-01  6:42:01 | 2011-11-30 18:05:23 |
      | sample.txt   | 2011-12-01 13:45 | sean@intersect.org.au     |                     |                     |

  Scenario: Sort the list of files by descending emails
    Given I have data files
      | filename     | created_at       | uploaded_by               | start_time           | end_time                |
      | datafile.dat | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 UTC | 30/11/2011 18:05:23 UTC |
      | sample.txt   | 01/12/2011 13:45 | sean@intersect.org.au     |                      |                         |
    When I am on the list data files page
    And I follow "Added by"
    And I follow "Added by"
    Then I should see "exploredata" table with
      | Filename     | Date added       | Added by                  | Start time          | End time            |
      | sample.txt   | 2011-12-01 13:45 | sean@intersect.org.au     |                     |                     |
      | datafile.dat | 2011-11-30 10:15 | georgina@intersect.org.au | 2010-06-01  6:42:01 | 2011-11-30 18:05:23 |

  Scenario: User clicks download without selecting files
    Given I have data files
      | filename    | created_at       | uploaded_by               | start_time       | end_time            | path                |
      | sample1.txt | 01/12/2011 13:45 | sean@intersect.org.au     | 1/6/2010 6:42:01 | 30/11/2011 18:05:23 | samples/sample1.txt |
      | sample2.txt | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 | 30/11/2011 18:05:23 | samples/sample2.txt |
    When I am on the list data files page
    And I click on "Download"
    And I press "Download Selected Files"
    Then I should see "No files were selected for download"

  Scenario: User downloads a selection of files
    Given I have data files
      | filename    | created_at       | uploaded_by               | start_time       | end_time            | path                |
      | sample1.txt | 01/12/2011 13:45 | sean@intersect.org.au     | 1/6/2010 6:42:01 | 30/11/2011 18:05:23 | samples/sample1.txt |
      | sample2.txt | 30/11/2011 10:15 | georgina@intersect.org.au | 1/6/2010 6:42:01 | 30/11/2011 18:05:23 | samples/sample2.txt |
    When I am on the list data files page
    And I click on "Download"
    And I check "ids[]"
    And I press "Download Selected Files"
    Then I should get a download of all data files

