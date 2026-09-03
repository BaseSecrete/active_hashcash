# IPv4 reputation ranges are stored in the database.
# This migration creates the table for the model ActiveHashcash::Reputation::IPv4.
# Run the following commands to add it to your Rails application:
#
#   rails active_hashcash:install:migrations
#   rails db:migrate
#
class CreateActiveHashcashReputationIpv4s < ActiveRecord::Migration[5.2]
  def change
    create_table :active_hashcash_reputation_ipv4s do |t|
      # 4-byte binary: most memory-efficient IPv4 storage; unsigned int is not supported by all databases.
      t.binary :range_start, limit: 4, null: false
      t.binary :range_end, limit: 4, null: false
      t.integer :tor_score, limit: 1, null: false, default: 0
      t.integer :spamhaus_score, limit: 1, null: false, default: 0
      t.integer :ipsum_score, limit: 1, null: false, default: 0
      t.integer :abuse_score, limit: 1, null: false, default: 0
      t.integer :anonymous_score, limit: 1, null: false, default: 0
      t.integer :attack_score, limit: 1, null: false, default: 0
    end
    add_index :active_hashcash_reputation_ipv4s, [:range_start, :range_end], unique: true, name: "index_active_hashcash_reputation_ipv4s_on_range"
  end
end
