# IPv4 reputation addresses and ranges are stored in the database.
# This migration creates the tables for ActiveHashcash::Reputation::IPv4Address
# and ActiveHashcash::Reputation::IPv4Range.
# Run the following commands to add them to your Rails application:
#
#   rails active_hashcash:install:migrations
#   rails db:migrate
#
class CreateActiveHashcashReputationIpv4s < ActiveRecord::Migration[5.2]
  def up
    # uint32 would have been the best choice for storing IPv4, but PostgreSQL does not support unsigned integers.
    # So, 4-byte binary column is a trade off for best efficiency compatible with PostgreSQL, MySQL and SQLite.
    create_table :active_hashcash_reputation_ipv4_addresses, id: false do |t|
      t.binary :id, limit: 4, null: false, primary_key: true
      t.integer :abuse_score, limit: 1, null: false, default: 0
      t.integer :anonymous_score, limit: 1, null: false, default: 0
      t.integer :attack_score, limit: 1, null: false, default: 0
    end

    create_table :active_hashcash_reputation_ipv4_ranges, primary_key: [:first_address, :last_address] do |t|
      t.binary :first_address, limit: 4, null: false
      t.binary :last_address, limit: 4, null: false
      t.integer :abuse_score, limit: 1, null: false, default: 0
      t.integer :anonymous_score, limit: 1, null: false, default: 0
      t.integer :attack_score, limit: 1, null: false, default: 0
    end

    # For SQLite, save space by suffixing the CREATE TABLE statements by `WITHOUT ROWID`:
    # execute <<-SQL
    #   CREATE TABLE IF NOT EXISTS "active_hashcash_reputation_ipv4_addresses" (
    #     "id" blob(4) NOT NULL,
    #     "abuse_score" integer(1) DEFAULT 0 NOT NULL,
    #     "anonymous_score" integer(1) DEFAULT 0 NOT NULL,
    #     "attack_score" integer(1) DEFAULT 0 NOT NULL,
    #     PRIMARY KEY ("id")
    #   ) WITHOUT ROWID;
    # SQL
    # execute <<-SQL
    #   CREATE TABLE IF NOT EXISTS "active_hashcash_reputation_ipv4_ranges" (
    #     "first_address" blob(4) NOT NULL,
    #     "last_address" blob(4) NOT NULL,
    #     "abuse_score" integer(1) DEFAULT 0 NOT NULL,
    #     "anonymous_score" integer(1) DEFAULT 0 NOT NULL,
    #     "attack_score" integer(1) DEFAULT 0 NOT NULL,
    #     PRIMARY KEY ("first_address", "last_address")
    #   ) WITHOUT ROWID;
    # SQL
  end

  def down
    drop_table :active_hashcash_reputation_ipv4_addresses
    drop_table :active_hashcash_reputation_ipv4_ranges
  end
end
