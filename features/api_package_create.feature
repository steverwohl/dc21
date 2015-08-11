
Feature: Create a package from the API
  In order to handle multiple data files which belong to a group
  As a user
  I want to bundle them into a package for upload/download

  Background:
    Given I have a user "researcher@intersect.org.au" with role "Institutional User"
    And user "researcher@intersect.org.au" has an API token
    And I have facility "ROS Weather Station" with code "ROS_WS"
    And I have facility "Flux Tower" with code "FLUX"
    And I have data files
      | filename    | created_at       | uploaded_by            | start_time       | end_time            | path                | id |
      | sample1.txt | 01/12/2011 13:45 | sean@intersect.org.au  | 1/6/2010 6:42:01 | 30/11/2011 18:05:23 | samples/sample1.txt | 1  |
      | sample2.txt | 30/11/2011 10:15 | admin@intersect.org.au | 1/6/2010 6:42:01 | 30/11/2011 18:05:23 | samples/sample2.txt | 2  |
      | sample3.txt | 30/12/2011 12:34 | admin@intersect.org.au |                  |                     | samples/sample3.txt | 3  |
    And I have experiments
      | name              | facility            | id |
      | My Experiment     | ROS Weather Station | 1  |
      | Rain Experiment   | ROS Weather Station | 2  |
      | Flux Experiment 1 | Flux Tower          | 3  |
      | Flux Experiment 2 | Flux Tower          | 4  |
      | Flux Experiment 3 | Flux Tower          | 5  |
    And I have tags
      | name       |
      | Photo      |
      | Video      |
      | Gap-Filled |

  Scenario: Try to package without an API token
    When I perform an API package create without an API token
      | | |
    Then I should get a 401 response code

  Scenario: Try to package with an invalid API token
    When I perform an API package create with an invalid API token
      | | |
    Then I should get a 401 response code

  Scenario: Try to package with no arguments
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | | |
    Then I should get a 400 response code
    And I should get a JSON response with message "file_ids is required and must be an Array"

  Scenario: Try to package with invalid file id
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids | abc_123 |
    Then I should get a 400 response code
    And I should get a JSON response with message "file id 'abc_123' is not a valid file id"

  Scenario: Try to package with a file id that does not exist
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids | 1,2,3,4 |
    Then I should get a 400 response code
    And I should get a JSON response with message "file with id '4' could not be found"

  Scenario: Try to package without a filename, experiment or title
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids | 1,2,3 |
    Then I should get a 400 response code
    And I should get a JSON response with message "filename can't be blank"
    And I should get a JSON response with message "experiment_id can't be blank"
    And I should get a JSON response with message "title can't be blank"

  Scenario: Try to package with invalid access rights type
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids           | 1                   |
      | access_rights_type | BadAccessRightsType |
    Then I should get a 400 response code
    And I should get a JSON response with message "access_rights_type must be one of: Open, Conditional, Restricted"

  Scenario: package is created successfully in the background
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids      | 1,2,3            |
      | filename      | my_package       |
      | experiment_id | 1                |
      | title         | my magic package |
    Then I should get a 200 response code
    And I should get a JSON response with message "Package is now queued for processing in the background."
    And I should get a JSON response with package name "my_package.zip"
    And file "my_package.zip" should have experiment "My Experiment"
    And file "my_package.zip" should have title "my magic package"
    And file "my_package.zip" should have transfer status "QUEUED"
    And file "my_package.zip" should have access rights type "Open"

  Scenario: package is created successfully in the foreground
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids          | 1,2,3            |
      | filename          | my_package       |
      | experiment_id     | 1                |
      | title             | my magic package |
      | run_in_background | false            |
    Then I should get a 200 response code
    And I should get a JSON response with message "Package was successfully created."
    And I should get a JSON response with package name "my_package.zip"
    And file "my_package.zip" should have experiment "My Experiment"
    And file "my_package.zip" should have title "my magic package"
    And file "my_package.zip" should have transfer status "COMPLETE"
    And file "my_package.zip" should have access rights type "Open"

  Scenario: package is created successfully with all the options
    When I perform an API package create with the following parameters as user "researcher@intersect.org.au"
      | file_ids           | 1,2,3                     |
      | filename           | my_package                |
      | experiment_id      | 1                         |
      | title              | my magic package          |
      | run_in_background  | false                     |
      | description        | some friendly description |
      | tag_names          | "Photo","Video"           |
      | label_names        | "Label1","Label2"         |
      | start_time         | 2011-10-10 01:01:01       |
      | end_time           | 2011-11-11 02:02:02       |
      | run_in_background  | false                     |
      | access_rights_type | Restricted                |
    Then I should get a 200 response code
    And I should get a JSON response with message "Package was successfully created."
    And I should get a JSON response with package name "my_package.zip"
    And file "my_package.zip" should have experiment "My Experiment"
    And file "my_package.zip" should have title "my magic package"
    And file "my_package.zip" should have transfer status "COMPLETE"
    And file "my_package.zip" should have description "some friendly description"
    And file "my_package.zip" should have label "Label1"
    And file "my_package.zip" should have label "Label2"
    And file "my_package.zip" should have tag "Photo"
    And file "my_package.zip" should have tag "Video"
    And file "my_package.zip" should have start time "2011-10-10 01:01:01"
    And file "my_package.zip" should have end time "2011-11-11 02:02:02"
    And file "my_package.zip" should have access rights type "Restricted"


