#!/bin/env ruby
# encoding: utf-8

def populate_data
  load_password
  create_test_users
  create_facilities_and_experiments
  create_test_files
  create_column_mappings
  create_groups
end

def create_test_files
  DataFile.delete_all
  ColumnDetail.delete_all
  MetadataItem.delete_all
  create_data_file("sample1.txt", "researcher1@intersect.org.au")
  create_data_file("sample2.txt", "daniel@intersect.org.au")
  create_data_file("weather_station_15_min.dat", "daniel@intersect.org.au")
  create_data_file("weather_station_05_min.dat", "researcher1@intersect.org.au")
  create_data_file("weather_station_table_2.dat", "researcher2@intersect.org.au")
  create_data_file("sample3.txt", "researcher1@intersect.org.au")
  create_data_file("WTC01_Table1.dat", "researcher2@intersect.org.au")
  create_data_file("WTC02_Table1.dat", "daniel@intersect.org.au")
  create_data_file("VeryLongFileNameForTestingFileNameExtremeLength_2011Data_TestOnly.dat", "daniel@intersect.org.au")

  test_file = DataFile.find_by_filename("VeryLongFileNameForTestingFileNameExtremeLength_2011Data_TestOnly.dat")
  test_file.file_processing_description = "Test ~!@\#$\%^\&*()_\+\`567890-={}[]|:\";'<>?,./ TestTestTest Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 500 Characters Test"
  test_file.save
end

def create_test_users
  User.delete_all
  create_user(:email => "kali@intersect.org.au", :first_name => "Admin", :last_name => "User")
  create_user(:email => "daniel@intersect.org.au", :first_name => "Admin", :last_name => "User")
  create_user(:email => "cindy@intersect.org.au", :first_name => "Admin", :last_name => "User")
  create_user(:email => "cathy@intersect.org.au", :first_name => "Admin", :last_name => "User")
  create_user(:email => "researcher1@intersect.org.au", :first_name => "Researcher", :last_name => "One")
  r2 = create_user(:email => "researcher2@intersect.org.au", :first_name => "Researcher", :last_name => "Two")
  r2.deactivate
  create_user(:email => "apgr@intersect.org.au", :first_name => "API", :last_name => "Group")
  create_user(:email => "adgr@intersect.org.au", :first_name => "Admin", :last_name => "Group")
  create_user(:email => "ingr@intersect.org.au", :first_name => "Institution", :last_name => "Group")
  create_user(:email => "noningr@intersect.org.au", :first_name => "Non-Institution", :last_name => "Group")
  create_rejected_user(:email => "rejected@intersect.org.au", :first_name => "Rejected", :last_name => "One")
  create_unapproved_user(:email => "unapproved1@intersect.org.au", :first_name => "Unapproved", :last_name => "One")
  create_unapproved_user(:email => "unapproved2@intersect.org.au", :first_name => "Unapproved", :last_name => "Two")
  set_role("researcher1@intersect.org.au", "Institutional User")
  set_role("researcher2@intersect.org.au", "Institutional User")
  set_role("kali@intersect.org.au", "Administrator")
  set_role("daniel@intersect.org.au", "Administrator")
  set_role("cathy@intersect.org.au", "Non-Institutional User")
  set_role("cindy@intersect.org.au", "Administrator")
  set_role("apgr@intersect.org.au", "API Uploader")
  set_role("adgr@intersect.org.au", "Administrator")
  set_role("ingr@intersect.org.au", "Institutional User")
  set_role("noningr@intersect.org.au", "Non-Institutional User")
end


def create_data_file(filename, uploader)
  # we use the attachment builder to create the sample files so we know they've been processed the same way as if uploaded
  file = Rack::Test::UploadedFile.new("#{Rails.root}/samples/#{filename}", "application/octet-stream")
  builder = AttachmentBuilder.new(APP_CONFIG['files_root'], User.find_for_authentication(email: uploader), FileTypeDeterminer.new, MetadataExtractor.new)

  experiment_id = Experiment.first.id

  experiment_id = Experiment.last.id if filename == "VeryLongFileNameForTestingFileNameExtremeLength_2011Data_TestOnly.dat"

  builder.build(file, experiment_id, DataFile::STATUS_RAW, "")
  df = DataFile.last
  rand_mins = rand(10000)
  # make the created at semi-random
  df.created_at = df.created_at - rand_mins.minutes
  df.save!
end

def set_role(email, role)
  user = User.find_for_authentication(email: email)
  role = Role.find_by_name(role)
  user.role = role
  user.save!
end

def create_user(attrs)
  user = User.new(attrs.merge(:password => @password))
  user.activate
  user.save!
  user
end

def create_rejected_user(attrs)
  user = User.new(attrs.merge(:password => @password))
  user.status = "R"
  user.save!
  user
end

def create_unapproved_user(attrs)
  user = User.create!(attrs.merge(:password => @password))
  user.save!
  user
end

def get_file_path
  config_file = File.expand_path('../../../config/dc21_config.yml', __FILE__)
  config = YAML::load_file(config_file)
  env = ENV["RAILS_ENV"] || "development"
  config[env]['files_root']
end

def load_password
  password_file = File.expand_path("#{Rails.root}/tmp/env_config/sample_password.yml", __FILE__)
  if File.exists? password_file
    puts "Using sample user password from #{password_file}"
    password = YAML::load_file(password_file)
    @password = password[:password]
    return
  end

  if Rails.env.development?
    puts "#{password_file} missing.\n" +
             "Set sample user password:"
    input = STDIN.gets.chomp
    buffer = Hash[:password => input]
    Dir.mkdir("#{Rails.root}/tmp", 0755) unless Dir.exists?("#{Rails.root}/tmp")
    Dir.mkdir("#{Rails.root}/tmp/env_config", 0755) unless Dir.exists?("#{Rails.root}/tmp/env_config")
    File.open(password_file, 'w') do |out|
      YAML::dump(buffer, out)
    end
    @password = input
  else
    raise "No sample password file provided, and it is required for any environment that isn't development\n" +
              "Use capistrano's deploy:populate task to generate one"
  end

end

def create_facilities_and_experiments
  Facility.delete_all
  Experiment.delete_all

  user = User.first
  ws = create_facility(:name => "Rainout Shelter Weather Station", :code => "ROS_WS", :primary_contact => user)
  ws.experiments.create!(:name => "The Rain Experiment", :start_date => "2012-01-01", :access_rights => "http://creativecommons.org/licenses/by-sa/4.0", :subject => "Rain")
  ws.experiments.create!(:name => "The Wind Experiment", :start_date => "2011-01-20", :access_rights => "http://creativecommons.org/licenses/by-nc-sa/4.0", :subject => "Wind")

  test = create_facility(:name => "Test Facility", :code => "T1", :primary_contact => user)
  test.experiments.create(:name => "Test Experiment 1", :start_date => "2012-01-01", :access_rights => "http://creativecommons.org/licenses/by-sa/4.0", :subject => "Test1")
  test.experiments.create(:name => "Test Experiment 2", :start_date => "2011-01-20", :access_rights => "http://creativecommons.org/licenses/by-nc-sa/4.0", :subject => "Test2")
  test.experiments.create(:name => "Test Experiment 3", :start_date => "2012-06-01", :access_rights => "http://creativecommons.org/licenses/by-nc-nd/4.0", :subject => "Test3")

  other = create_facility(:name => "Other", :code => "Other Code", :primary_contact => user)
  #other.id = -1
  other_experiment = other.experiments.create(:name => "Other", :start_date => "2012-01-01", :access_rights => "http://creativecommons.org/licenses/by-sa/4.0", :subject => "Other subject")
  #other_experiment.id = -1
  #other_experiment.save!
  #other.save

  fac = create_facility(:name => "TestLongFacilityNameForTestingTestLongFacilityName",
      :code => "TLFNFT",
      :primary_contact => user,
      :description => "Test ~!@\#$\%^\&*()_\+\`567890-={}[]|:”;’<>?,./ TestTestTest Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 500 Characters Test",
      :a_lat => -90,
      :a_long => -180,
      :b_lat => 90,
      :b_long => 180)

  fac.experiments.create(:name => "TestLongExperimentNameForTestingTestLongExperimentNameTest TestLongExperimentNameForTestingTestLongExperimentNameTest ",
      :start_date => "2012-01-01",
      :access_rights => "http://creativecommons.org/licenses/by-sa/3.0/au",
      :subject => "Test1",
      :description => "Test ~!@\#$\%^\&*()_\+\`567890-={}[]|:”;’<>?,./ TestTestTest Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test 500 Characters Test")

end

def create_facility(attrs)
  facility = Facility.new(attrs)
  facility.save!
  facility
end

def create_column_mappings
  ColumnMapping.delete_all
  create_mapping(:name => "Average Soil Temp (Probe1)", :code => "SoilTempProbe_Avg(1)")
  create_mapping(:name => "Average Soil Temp (Probe2)", :code => "SoilTempProbe_Avg(2)")
  create_mapping(:name => "Average Soil Temp (Probe3)", :code => "SoilTempProbe_Avg(3)")
  create_mapping(:name => "Average Soil Temp (Probe4)", :code => "SoilTempProbe_Avg(4)")
  create_mapping(:name => "Average Soil Temp (Probe5)", :code => "SoilTempProbe_Avg(5)")
  create_mapping(:name => "Average Soil Temp (Probe6)", :code => "SoilTempProbe_Avg(6)")
  create_mapping(:name => "Temperature", :code => "PTemp_C_Max")
  create_mapping(:name => "Temperature", :code => "PTemp")
  create_mapping(:name => "Wind Speed", :code => "WndSpd")
end

def create_mapping(attrs)
  mapping = ColumnMapping.new(attrs)
  mapping.save!
  mapping
end

def create_groups
	AccessGroup.delete_all

  create_group(:name => "Kali's Group",
  :primary_user => "adgr@intersect.org.au",
  :users => ["apgr@intersect.org.au", "ingr@intersect.org.au", "noningr@intersect.org.au"])

  create_group(:name => "Another Group",
   :primary_user => "ingr@intersect.org.au",
   :users => ["apgr@intersect.org.au", "adgr@intersect.org.au", "noningr@intersect.org.au"])
  create_group(:name => "A Third Group",
   :primary_user => "apgr@intersect.org.au",
   :users => ["adgr@intersect.org.au", "ingr@intersect.org.au", "noningr@intersect.org.au"])
end

def create_group(attrs)
  attrs[:primary_user] = User.find_by_email attrs[:primary_user]
  user_ids = attrs[:users].map{|email| User.find_by_email email}
  attrs[:users] = user_ids
  group = AccessGroup.new attrs
  group.save!
  group
end
