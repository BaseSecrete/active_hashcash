# IPv4 reputation ranges are stored in the database.
# This migration creates the table for the model ActiveHashcash::Reputation::IPv4.
# Run the following commands to add it to your Rails application:
#
#   rails active_hashcash:install:migrations
#   rails db:migrate
#
class CreateActiveHashcashReputationIpv4s < ActiveRecord::Migration[5.2]
  def up
    create_table :active_hashcash_reputation_ipv4s, primary_key: [:first_address, :last_address] do |t|
      # uint32 would have been the best choice for storing IPv4, but PostgreSQL does not support unsigned integers.
      # So, 4-byte binary column is a trade off for best efficiency compatible with PostgreSQL, MySQL and SQLite.
      t.binary :first_address, limit: 4, null: false
      t.binary :last_address, limit: 4, null: false
      t.integer :abuse_score, limit: 1, null: false, default: 0
      t.integer :anonymous_score, limit: 1, null: false, default: 0
      t.integer :attack_score, limit: 1, null: false, default: 0
    end

    # For SQLite, save space by suffixing the CREATE TABLE statement by `WITHOUT ROWID`:
    # execute <<-SQL
    #   CREATE TABLE IF NOT EXISTS "active_hashcash_reputation_ipv4s" (
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
    drop_table :active_hashcash_reputation_ipv4s
  end
end
