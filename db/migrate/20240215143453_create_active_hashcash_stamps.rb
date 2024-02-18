class CreateActiveHashcashStamps < ActiveRecord::Migration[5.2]
  def change
    create_table :active_hashcash_stamps do |t|
      t.string :version, null: false
      t.integer :bits, null: false
      t.date :date, null: false
      t.string :resource, null: false
      t.string :ext, null: false
      t.string :rand, null: false
      t.string :counter, null: false
      t.string :request_path
      t.string :ip_address
      t.jsonb :context
      t.timestamps
    end
    add_index :active_hashcash_stamps, [:ip_address, :created_at], where: "ip_address IS NOT NULL"
    add_index :active_hashcash_stamps, [:counter, :rand, :date, :resource, :bits, :version, :ext], name: "index_active_hashcash_stamps_unique", unique: true
  end
end
