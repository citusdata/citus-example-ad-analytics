class InitialTables < ActiveRecord::Migration
  def up
    execute <<-SQL
    CREATE TYPE campaign_cost_model AS ENUM ('cost_per_click', 'cost_per_impression');
    CREATE TYPE campaign_state AS ENUM ('paused', 'running', 'archived');
    CREATE TYPE campaign_budget_interval AS ENUM ('daily', 'weekly', 'monthly');
    SQL

    create_table :accounts do |t|
      t.text :email, null: false, unique: true
      t.text :encrypted_password, null: false
      t.text :name, null: false
      t.text :image_url, null: false

      t.timestamps null: false
    end

    create_table :campaigns do |t|
      t.references :account, null: false, index: true

      t.text :name, null: false
      t.column :cost_model, :campaign_cost_model, null: false
      t.column :state, :campaign_state, null: false
      t.integer :budget, null: true
      t.column :budget_interval, :campaign_budget_interval, null: true
      t.string :blacklisted_site_urls, array: true

      t.timestamps null: false
    end

    create_table :ads do |t|
      t.references :campaign, null: false, index: true

      t.text :name, null: false
      t.text :image_url, null: false
      t.text :target_url, null: false

      t.timestamps null: false
    end

    create_table :impressions, id: false do |t|
      t.uuid :id, null: false
      t.references :ad, null: false, index: true
      t.timestamp :seen_at, null: false

      t.text :site_url, null: false
      t.decimal :cost_per_impression_usd, precision: 20, scale: 10, null: true

      t.inet :user_ip, null: false
      t.jsonb :user_data, null: false # agent, is_mobile, location
    end

    create_table :clicks, id: false do |t|
      t.uuid :id, null: false
      t.references :ad, null: false, index: true
      t.timestamp :clicked_at, null: false

      t.text :site_url, null: false
      t.decimal :cost_per_click_usd, precision: 20, scale: 10, null: true

      t.inet :user_ip, null: false
      t.jsonb :user_data, null: false # agent, is_mobile, location
    end

    execute "SELECT master_create_distributed_table('impressions', 'ad_id', 'hash')"
    execute "SELECT master_create_distributed_table('clicks', 'ad_id', 'hash')"
    execute "SELECT master_create_worker_shards('impressions', 16, 1)"
    execute "SELECT master_create_worker_shards('clicks', 16, 1)"
  end

  def down
    drop_table :accounts
    drop_table :campaigns
    drop_table :ads

    execute <<-SQL
    DROP TYPE campaign_cost_model;
    DROP TYPE campaign_state;
    DROP TYPE campaign_budget_interval;
    SQL

    # Distributed tables can't be dropped within a transaction
    execute 'COMMIT'
    drop_table :impressions
    drop_table :clicks
    execute 'BEGIN'
  end
end
