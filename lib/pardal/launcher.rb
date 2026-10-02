# frozen_string_literal: true

require "pathname"
require "rbconfig"

module Pardal
  # Prepares the runtime before anything else is loaded.
  #
  # This is the first code the executable loads and it uses only the standard
  # library, because it also runs when the gems are not installed yet: Thor,
  # Bundler and everything else in the Gemfile only exist after the bundle is
  # ready.
  #
  #   1. points Bundler at the Gemfile of the project and activates the bundle;
  #   2. when the gems are missing, installs them and starts the process again,
  #      so `setup` also works on a fresh clone, without asking the user to run
  #      `bundle install` by hand.
  #
  # When everything is ready - the usual case - nothing is printed and nothing
  # is installed: the happy path costs a single `require`.
  class Launcher
    # The bundle exists but is not ready yet (fresh clone, Gemfile changed, ...).
    class NotInstalled < StandardError; end

    # Marks the run that happens after an install, so a second failure does not
    # start the same cycle again.
    INSTALLED_FLAG = "PARDAL_GEMS_INSTALLED"

    def initialize(root: File.expand_path("../..", __dir__), entry: nil)
      @root = Pathname(root)
      @entry = entry || @root.join("bin", "pardal")
    end

    # Leaves the runtime ready to load the commands. When the gems are missing,
    # this installs them and does not come back: the process starts again with
    # the bundle in place.
    def boot
      ENV["BUNDLE_GEMFILE"] ||= root.join("Gemfile").to_s

      activate
    rescue NotInstalled => e
      raise e if ENV[INSTALLED_FLAG]

      install_and_restart(e)
    rescue LoadError => e
      # Bundler ships with Ruby. Without it nothing can be installed, so the
      # message says what to do instead of trying.
      abort "Bundler is not available (#{e.message}). Install it with: gem install bundler"
    end

    private

    attr_reader :root, :entry

    # Activating the bundle only puts the gems of the lockfile in the load
    # path, it does not load them - that is what config/boot.rb does, and the
    # application needs it while the commands do not.
    def activate
      require "bundler/setup"
    rescue Bundler::GemNotFound, Bundler::GemfileNotFound => e
      raise NotInstalled, e.message
    end

    # Both the install and the restart run in other processes on purpose: the
    # process that failed carries a stale Bundler state, and a new one starts
    # from a bundle that is ready.
    def install_and_restart(error)
      announce_install
      abort "Could not install the gems:\n#{error.message}" unless install_gems

      ENV[INSTALLED_FLAG] = "1"
      exec(RbConfig.ruby, entry.to_s, *ARGV)
    end

    def announce_install
      puts "The gems of the project are missing (first run, or the Gemfile changed)."
      puts "Installing them with `bundle install`..."
      puts

      # `exec` replaces the process, and a buffered message would go with it.
      $stdout.flush
    end

    def install_gems
      system(RbConfig.ruby, "-S", "bundle", "install", chdir: root.to_s)
    end
  end
end
