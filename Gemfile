source "https://rubygems.org"

ruby ">= 3.2"

# Web
gem "puma", "~> 8.0"
gem "sinatra", "~> 4.2", require: "sinatra/base"

# Persistence
gem "activerecord", "~> 8.1"
gem "bcrypt", "~> 3.1"
gem "sinatra-activerecord", "~> 2.0", require: "sinatra/activerecord"
gem "sqlite3", "~> 2.9"

# Configuration
gem "dotenv", "~> 3.2"

# Command line interface (bin/pardal)
gem "thor", "~> 1.5"

group :development, :test do
  gem "minitest", "~> 6.0"
  gem "rack-test", "~> 2.2"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.13"
end