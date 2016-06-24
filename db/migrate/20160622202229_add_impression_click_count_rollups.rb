class AddImpressionClickCountRollups < ActiveRecord::Migration
  def up
    create_table :impression_daily_rollups, id: false do |t|
      t.uuid :ad_id, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    create_table :click_daily_rollups, id: false do |t|
      t.uuid :ad_id, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    execute "ALTER TABLE impression_daily_rollups ADD PRIMARY KEY(ad_id, date)"
    execute "ALTER TABLE click_daily_rollups ADD PRIMARY KEY(ad_id, date)"

    execute "SELECT master_create_distributed_table('impression_daily_rollups', 'ad_id', 'hash')"
    execute "SELECT master_create_distributed_table('click_daily_rollups', 'ad_id', 'hash')"
    execute "SELECT master_create_worker_shards('impression_daily_rollups', 16, 1)"
    execute "SELECT master_create_worker_shards('click_daily_rollups', 16, 1)"

    execute "CREATE INDEX impressions_seen_at_brin ON impressions USING brin(seen_at)"
    execute "CREATE INDEX clicks_clicked_at_brin ON clicks USING brin(clicked_at)"
  end

  def down
    execute "DROP INDEX impressions_seen_at_brin"
    execute "DROP INDEX clicks_clicked_at_brin"

    # Distributed tables can't be dropped within a transaction
    execute 'COMMIT'
    drop_table :impression_daily_rollups
    drop_table :click_daily_rollups
    execute 'BEGIN'
  end
end
