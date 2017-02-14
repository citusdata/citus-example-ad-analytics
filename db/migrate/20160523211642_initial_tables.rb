class InitialTables < ActiveRecord::Migration
  def up
    enable_extension_on_all_nodes 'uuid-ossp'

    execute_on_all_nodes "CREATE TYPE campaign_cost_model AS ENUM ('cost_per_click', 'cost_per_impression')"
    execute_on_all_nodes "CREATE TYPE campaign_state AS ENUM ('paused', 'running', 'archived')"

    create_table :users do |t|
      t.references :company, null: false
      t.text :encrypted_password, null: false
      t.text :email, null: false, unique: true
      t.timestamps null: false
    end

    create_table :companies, partition_key: :id do |t|
      t.text :name, null: false
      t.text :image_url, null: false
      t.timestamps null: false
    end

    create_table :campaigns, partition_key: :company_id do |t|
      t.references :company, null: false

      t.text :name, null: false
      t.column :cost_model, :campaign_cost_model, null: false
      t.column :state, :campaign_state, null: false
      t.integer :monthly_budget, null: true
      t.string :blacklisted_site_urls, array: true

      t.timestamps null: false
    end

    create_table :ads, partition_key: :company_id do |t|
      t.references :company, null: false
      t.references :campaign, null: false

      t.text :name, null: false
      t.text :image_url, null: false
      t.text :target_url, null: false

      t.integer :impressions_count, null: false, default: 0, limit: 8
      t.integer :clicks_count, null: false, default: 0, limit: 8

      t.timestamps null: false
    end

    create_table :impressions, id: :uuid, partition_key: :company_id do |t|
      t.references :company, null: false
      t.references :ad, null: false
      t.timestamp :seen_at, null: false, index: true

      t.text :site_url, null: false
      t.decimal :cost_per_impression_usd, precision: 20, scale: 10, null: true

      t.inet :user_ip, null: false
      t.jsonb :user_data, null: false # agent, is_mobile, location
    end

    create_table :clicks, id: :uuid, partition_key: :company_id do |t|
      t.references :company, null: false
      t.references :ad, null: false
      t.timestamp :clicked_at, null: false, index: true

      t.text :site_url, null: false
      t.decimal :cost_per_click_usd, precision: 20, scale: 10, null: true

      t.inet :user_ip, null: false
      t.jsonb :user_data, null: false # agent, is_mobile, location
    end

    create_distributed_table :companies, :id
    create_distributed_table :campaigns, :company_id
    create_distributed_table :ads, :company_id
    create_distributed_table :impressions, :company_id
    create_distributed_table :clicks, :company_id
  end

  def down
    drop_table :users

    # DROP TABLE statements can't run in a transaction block (Citus #774)
    execute 'COMMIT'
    drop_table :companies
    drop_table :campaigns
    drop_table :ads
    drop_table :impressions
    drop_table :clicks
    execute 'BEGIN'

    execute_on_all_nodes 'DROP TYPE campaign_cost_model'
    execute_on_all_nodes 'DROP TYPE campaign_state'
    execute_on_all_nodes 'DROP TYPE campaign_budget_interval'
  end
end
