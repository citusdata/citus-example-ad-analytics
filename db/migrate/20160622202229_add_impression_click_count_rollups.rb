class AddImpressionClickCountRollups < ActiveRecord::Migration
  def up
    create_table :impression_daily_rollups, id: :uuid, partition_key: :account_id do |t|
      t.references :account, null: false
      t.references :ad, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    create_table :click_daily_rollups, id: :uuid, partition_key: :account_id do |t|
      t.references :account, null: false
      t.references :ad, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    create_distributed_table :impression_daily_rollups, :account_id
    create_distributed_table :click_daily_rollups, :account_id
  end

  def down
    # DROP TABLE statements can't run in a transaction block (Citus #774)
    execute 'COMMIT'
    drop_table :impression_daily_rollups
    drop_table :click_daily_rollups
    execute 'BEGIN'
  end
end
