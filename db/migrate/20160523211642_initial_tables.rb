class InitialTables < ActiveRecord::Migration
  def up
    enable_extension 'uuid-ossp'

    execute <<-SQL
    CREATE TYPE campaign_cost_model AS ENUM ('cost_per_click', 'cost_per_impression');
    CREATE TYPE campaign_state AS ENUM ('paused', 'running', 'archived');
    CREATE TYPE campaign_budget_interval AS ENUM ('daily', 'weekly', 'monthly');
    SQL

    create_table :accounts do |t|
      t.text :encrypted_password, null: false
      t.text :name, null: false
      t.text :image_url, null: false

      t.timestamps null: false
    end

    create_table :account_emails do |t|
      t.references :account, null: false
      t.text :email, null: false, unique: true
    end

    create_table :campaigns do |t|
      t.references :account, null: false

      t.text :name, null: false
      t.column :cost_model, :campaign_cost_model, null: false
      t.column :state, :campaign_state, null: false
      t.integer :budget, null: true
      t.column :budget_interval, :campaign_budget_interval, null: true
      t.string :blacklisted_site_urls, array: true

      t.timestamps null: false
    end

    create_table :ads do |t|
      t.references :account, null: false
      t.references :campaign, null: false

      t.text :name, null: false
      t.text :image_url, null: false
      t.text :target_url, null: false

      t.integer :impressions_count, null: false, default: 0, limit: 8
      t.integer :clicks_count, null: false, default: 0, limit: 8

      t.timestamps null: false
    end

    create_table :impressions, id: :uuid do |t|
      t.references :account, null: false
      t.references :ad, null: false
      t.timestamp :seen_at, null: false

      t.text :site_url, null: false
      t.decimal :cost_per_impression_usd, precision: 20, scale: 10, null: true

      t.inet :user_ip, null: false
      t.jsonb :user_data, null: false # agent, is_mobile, location
    end

    create_table :clicks, id: :uuid do |t|
      t.references :account, null: false
      t.references :ad, null: false
      t.timestamp :clicked_at, null: false

      t.text :site_url, null: false
      t.decimal :cost_per_click_usd, precision: 20, scale: 10, null: true

      t.inet :user_ip, null: false
      t.jsonb :user_data, null: false # agent, is_mobile, location
    end

    execute "ALTER TABLE campaigns DROP CONSTRAINT campaigns_pkey"
    execute "ALTER TABLE campaigns ADD PRIMARY KEY (account_id, id)"
    execute "ALTER TABLE ads DROP CONSTRAINT ads_pkey"
    execute "ALTER TABLE ads ADD PRIMARY KEY (account_id, id)"
    execute "ALTER TABLE impressions DROP CONSTRAINT impressions_pkey"
    execute "ALTER TABLE impressions ADD PRIMARY KEY (account_id, id, ad_id)"
    execute "ALTER TABLE clicks DROP CONSTRAINT clicks_pkey"
    execute "ALTER TABLE clicks ADD PRIMARY KEY (account_id, id, ad_id)"

    execute "SELECT master_create_distributed_table('accounts', 'id', 'hash')"
    execute "SELECT master_create_distributed_table('campaigns', 'account_id', 'hash')"
    execute "SELECT master_create_distributed_table('ads', 'account_id', 'hash')"
    execute "SELECT master_create_distributed_table('impressions', 'account_id', 'hash')"
    execute "SELECT master_create_distributed_table('clicks', 'account_id', 'hash')"
    execute "SELECT master_create_worker_shards('accounts', 16, 1)"
    execute "SELECT master_create_worker_shards('campaigns', 16, 1)"
    execute "SELECT master_create_worker_shards('ads', 16, 1)"
    execute "SELECT master_create_worker_shards('impressions', 16, 1)"
    execute "SELECT master_create_worker_shards('clicks', 16, 1)"
  end

  def down
    drop_table :account_emails

    # DROP TABLE statements can't run in a transaction block (Citus #774)
    execute 'COMMIT'
    drop_table :accounts
    drop_table :campaigns
    drop_table :ads
    drop_table :impressions
    drop_table :clicks
    execute 'BEGIN'

    execute <<-SQL
    DROP TYPE campaign_cost_model;
    DROP TYPE campaign_state;
    DROP TYPE campaign_budget_interval;
    SQL
  end
end
