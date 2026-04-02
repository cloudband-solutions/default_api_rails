class CreateCurrentSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_catalog.plpgsql" unless extension_enabled?("pg_catalog.plpgsql")
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.datetime :created_at, null: false
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :role, null: false, default: "admin"
      t.string :status, null: false
      t.datetime :updated_at, null: false
    end
  end
end
