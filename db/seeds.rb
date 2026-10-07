# frozen_string_literal: true

require "yaml"

# Seeds: populates the database from db/seeds/*.yml.
#
#   bundle exec rake db:seed   # loads users.yml, products.yml, payments.yml
#
# This is the `db/seeds.rb` file the `db:seed` task of the
# sinatra-activerecord gem loads, so no task is declared in the Rakefile.
#
# Each file holds a list of records; the loader is idempotent, so re-running
# it keeps the existing records instead of creating duplicates:
#   - users: matched by `email` (stripped and downcased, like the model);
#   - products: matched by `name`;
#   - payments: matched by `amount`; `status` is only applied on creation
#     (a payment created `pending` is transitioned once), so a payment the
#     user confirmed or cancelled through the API is never moved back.
module Seeds
  SEEDS_DIR = File.expand_path("seeds", __dir__)

  def self.load!(dir = SEEDS_DIR)
    users = load_users(File.join(dir, "users.yml"))
    products = load_products(File.join(dir, "products.yml"))
    payments = load_payments(File.join(dir, "payments.yml"))

    puts "Seeds loaded: #{users} user(s), #{products} product(s), #{payments} payment(s)."
  end

  def self.load_users(path)
    load_list(path).count do |attributes|
      email = attributes.fetch("email").to_s.strip.downcase
      user = User.find_or_initialize_by(email: email)
      next false unless user.new_record?

      user.assign_attributes(attributes.merge("email" => email))
      user.save!
      true
    end
  end

  def self.load_products(path)
    load_list(path).count do |attributes|
      product = Product.find_or_initialize_by(name: attributes.fetch("name").to_s)
      next false unless product.new_record?

      product.assign_attributes(attributes)
      product.save!
      true
    end
  end

  def self.load_payments(path)
    load_list(path).count do |attributes|
      amount = attributes.fetch("amount").to_s
      payment = Payment.find_by(amount: amount)
      next false if payment

      payment = Payment.create!(amount: amount)
      status = attributes["status"].to_s
      Payment.transition!(payment.id, to: status) unless status.empty? || status == Payment::DEFAULT_STATUS
      true
    end
  end

  def self.load_list(path)
    return [] unless File.exist?(path)

    records = YAML.safe_load_file(path)
    raise "Seeds file #{path} must hold a list of records." unless records.is_a?(Array)

    records
  end

  private_class_method :load_users, :load_products, :load_payments, :load_list
end

Seeds.load!
