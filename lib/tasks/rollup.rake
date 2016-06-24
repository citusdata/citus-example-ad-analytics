namespace :rollup do
  desc 'Rolls up counts of data in the impression/clicks tables created by the initial bulk load'
  task initial: :environment do
    ads = Ad.all

    puts format('Rolling up all historic data for %d ads', ads.size)
    ads.each do |ad|
      print '.'

      ImpressionDailyRollup.copy_from_client [:ad_id, :count, :date] do |copy|
        Impression.connection.select_rows(%{SELECT date_trunc('day', seen_at), COUNT(*) FROM impressions WHERE ad_id = '#{ad.id}' GROUP BY 1}).each do |date, count|
          copy << [ad.id, count.to_i, date]
        end
      end

      ClickDailyRollup.copy_from_client [:ad_id, :count, :date] do |copy|
        Click.connection.select_rows(%{SELECT date_trunc('day', clicked_at), COUNT(*) FROM clicks WHERE ad_id = '#{ad.id}' GROUP BY 1}).each do |date, count|
          copy << [ad.id, count.to_i, date]
        end
      end
    end
  end

  desc 'Rolls up counts of yesterday\'s data in the impression/clicks tables'
  task yesterday: :environment do
    date = Date.yesterday
    ads = Ad.all

    puts format('Rolling up yesterday for %d ads', ads.size)
    ads.each do |ad|
      print '.'
      click_count = Click.where(ad_id: ad.id, clicked_at: date.at_beginning_of_day..date.at_end_of_day).count

      ClickDailyRollup.connection.execute %{
        INSERT INTO click_daily_rollups (ad_id, count, date)
        VALUES ('#{ad.id}', #{click_count}, '#{date.to_s}')
        ON CONFLICT (ad_id, date)
        DO UPDATE SET count = EXCLUDED.count}

      impression_count = Impression.where(ad_id: ad.id, seen_at: date.at_beginning_of_day..date.at_end_of_day).count
      ImpressionDailyRollup.connection.execute %{
        INSERT INTO impression_daily_rollups (ad_id, count, date)
        VALUES ('#{ad.id}', #{impression_count}, '#{date.to_s}')
        ON CONFLICT (ad_id, date)
        DO UPDATE SET count = EXCLUDED.count}
    end

    puts ''
  end
end
