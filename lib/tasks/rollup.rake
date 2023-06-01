namespace :rollup do
  desc 'Rolls up counts of data in the impression/clicks tables created by the initial bulk load'
  task initial: :environment do
    ads = Ad.all

    puts format('Rolling up all historic data for %d ads', ads.size)
    ads.each do |ad|
      print '.'

      Impression.connection.select_rows(%{SELECT date_trunc('day', seen_at), COUNT(*) FROM impressions WHERE ad_id = '#{ad.id}' GROUP BY 1}).each do |date, count|
        puts " Impression ##{ad.id} #{date} #{count}"
        impression = ImpressionDailyRollup.create(ad_id: ad.id, company_id: ad.company_id, count: count.to_i, date: date)
        puts impression.inspect
      end

      Click.connection.select_rows(%{SELECT date_trunc('day', clicked_at), COUNT(*) FROM clicks WHERE ad_id = '#{ad.id}' GROUP BY 1}).each do |date, count|
        puts " Click ##{ad.id} #{date} #{count}"
        click = ClickDailyRollup.create(ad_id: ad.id, company_id: ad.company_id, count: count.to_i, date: date)
        puts click.inspect
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
