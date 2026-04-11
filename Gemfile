source "https://rubygems.org"

gemspec

gem "pry"
gem "mutex_m"
gem "logger"
gem "ostruct"
gem "bigdecimal"
gem "drb"
gem "sqlite3"

# Force modern Rails for Ruby 4.0+ compatibility
gem "rails", "~> 7.1"

# Hinting at development dependencies
# Prevents bundler from taking a long-time to resolve
group :development, :test do
  gem "activerecord-import"
  gem "bootsnap", require: false
  gem "builder"
  gem "rspec"
  gem "rubocop", require: false
  gem "rubocop-rails"
  gem "appraisal"
  gem "aruba", "~> 2.0"
  gem "aws-sdk-s3"
  gem "bundler"
  gem "capybara"
  gem "cucumber-expressions"
  gem "cucumber-rails"
  gem "fakeweb"
  gem "fog-aws"
  gem "fog-local"
  gem "generator_spec"
  gem "launchy"
  gem "nokogiri"
  gem "railties"
  gem "rake"
  gem "shoulda"
  gem "timecop"
end
