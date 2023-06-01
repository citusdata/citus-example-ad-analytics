class AddImpressionClickCountRollups < ActiveRecord::Migration[7.0]
  def up
    create_table :impression_daily_rollups, id: :uuid, partition_key: :company_id do |t|
      t.references :company, null: false
      t.references :ad, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    create_table :click_daily_rollups, id: :uuid, partition_key: :company_id do |t|
      t.references :company, null: false
      t.references :ad, null: false
      t.integer :count, limit: 8, null: false
      t.date :date, null: false
    end

    create_distributed_table :impression_daily_rollups, :company_id
    create_distributed_table :click_daily_rollups, :company_id
  end

  def down
    drop_table :impression_daily_rollups
    drop_table :click_daily_rollups
  end
end
