class AddImpressionClickCountRollups < ActiveRecord::Migration
  def up
    create_table :impression_daily_rollups, id: :uuid do |t|
      t.references :account, null: false
      t.references :ad, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    create_table :click_daily_rollups, id: :uuid do |t|
      t.references :account, null: false
      t.references :ad, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    execute "ALTER TABLE impression_daily_rollups DROP CONSTRAINT impression_daily_rollups_pkey"
    execute "ALTER TABLE impression_daily_rollups ADD PRIMARY KEY(account_id, ad_id, date, id)"
    execute "ALTER TABLE click_daily_rollups DROP CONSTRAINT click_daily_rollups_pkey"
    execute "ALTER TABLE click_daily_rollups ADD PRIMARY KEY(account_id, ad_id, date, id)"

    execute "SELECT master_create_distributed_table('impression_daily_rollups', 'account_id', 'hash')"
    execute "SELECT master_create_distributed_table('click_daily_rollups', 'account_id', 'hash')"
    execute "SELECT master_create_worker_shards('impression_daily_rollups', 16, 1)"
    execute "SELECT master_create_worker_shards('click_daily_rollups', 16, 1)"

    # DDL can't run within a transaction (Citus #668)
    execute 'COMMIT'
    execute "CREATE INDEX impressions_seen_at_brin ON impressions USING brin(seen_at)"
    execute "CREATE INDEX clicks_clicked_at_brin ON clicks USING brin(clicked_at)"
    execute 'BEGIN'
  end

  def down
    # DROP TABLE statements can't run in a transaction block (Citus #774)
    execute 'COMMIT'
    execute "DROP INDEX impressions_seen_at_brin"
    execute "DROP INDEX clicks_clicked_at_brin"
    drop_table :impression_daily_rollups
    drop_table :click_daily_rollups
    execute 'BEGIN'
  end
end
