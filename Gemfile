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
  # Interactive console of the `console` command. IRB and its prompt (Reline)
  # stopped being default gems in Ruby 4.0, and Reline needs Fiddle for the
  # prompt on Windows, so all three have to be declared to work under Bundler.
  gem "fiddle", "~> 1.1"
  gem "irb", "~> 1.18"

  gem "minitest", "~> 6.0"
  gem "rack-test", "~> 2.2"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.13"

  # Code checker of the `lint` task (see Rakefile and .rubocop.yml).
  gem "rubocop", "~> 1.91", require: false
end
