# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
ENV['SECRET_KEY_BASE'] ||= 'test_secret_key_base_32_bytes_minimum_length_required'
ENV['ALLOWED_ORIGINS'] ||= '*'
ENV['GEMINI_API_KEY'] ||= 'test_dummy_key'
ENV['GEMINI_LIVE_MODEL'] ||= 'gemini-live-test'
ENV['GEMINI_FLASH_MODEL'] ||= 'gemini-flash-test'
ENV['GEMINI_PRO_MODEL'] ||= 'gemini-pro-test'

require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end
