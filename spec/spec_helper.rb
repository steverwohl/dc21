require 'rubygems'

def clear_data_files
  `rm -r #{APP_CONFIG['files_root']}` if Dir.exists?(APP_CONFIG['files_root'])
  `mkdir -p #{APP_CONFIG['published_rif_cs_directory']}`
  `mkdir -p #{APP_CONFIG['unpublished_rif_cs_directory']}`
  `mkdir -p #{APP_CONFIG['archived_data_directory']}`
  `find /tmp -name download_zip* -type f -exec rm -f '{}' \\; 2>/dev/null`
end

require 'simplecov'
require 'simplecov-rcov'
require 'factory_girl_rails'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.formatter = :documentation

  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.before(:suite) {
    `echo '' > #{Rails.root}/log/test.log`
    clear_data_files
  }

  config.after(:suite) {
    clear_data_files
  }

  # Reset custom package_id before each test
  config.before(:each) {
    Rails.env = "test"
    ActiveRecord::Base.connection.execute "ALTER SEQUENCE package_id_seq RESTART WITH 1;"
    ActionMailer::Base.deliveries.clear
  }
end

class Warden::SessionSerializer
  def serialize(record)
    record
  end

  def deserialize(keys)
    keys
  end
end

RSpec::Matchers.define(:be_same_file_as) do |expected_file_path|
  match do |actual_file_path|

    md5_actual = md5_hash(actual_file_path)
    md5_expected = md5_hash(expected_file_path)

    unless md5_actual == md5_expected
      expected_contents = File.open(expected_file_path).read
      actual_contents = File.open(actual_file_path).read
      # print the files to make comparison easier
      puts "------------------------------"
      puts "Expected:"
      puts "------------------------------"
      puts expected_contents
      puts "------------------------------"
      puts "Actual:"
      puts "------------------------------"
      puts actual_contents
      puts "------------------------------"
    end

    md5_actual.should == md5_expected
  end

  def md5_hash(file_path)
    Digest::MD5.hexdigest(File.read(file_path))
  end
end

# e.g. path_to_foo.should be_same_file_as(path_to_bar)



