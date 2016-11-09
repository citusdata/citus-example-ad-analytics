# rubocop:disable all

def generate_fake_impressions(ad_id, impression_count, user_ips, ts_start, ts_end, cost_model)
  cpi_amount_range = rand(0.001..0.01)

  count = Impression.copy_from_client [:ad_id, :seen_at, :site_url, :user_ip, :user_data, :cost_per_impression_usd] do |copy|
    impression_count.times do |impression_num|
      print "  -> Generating impressions: #{impression_num}\r"
      copy << [ad_id, Faker::Time.between(ts_start, ts_end), Faker::Internet.url, user_ips[impression_num],
               { is_mobile: [true, false][rand(0..1)], location: Faker::Address.country_code },
               cost_model == 'cost_per_impression' ? rand(cpi_amount_range) : nil]
    end
  end

  puts "  -> Generated #{count} impressions" + " " * 10
end

def generate_fake_clicks(ad_id, click_count, user_ips, ts_start, ts_end, cost_model)
  cpc_amount_range = rand(1.0..5.0)

  count = Click.copy_from_client [:ad_id, :clicked_at, :site_url, :user_ip, :user_data, :cost_per_click_usd] do |copy|
    click_count.times do |click_num|
      print "  -> Generating clicks: #{click_num}\r"
      copy << [ad_id, Faker::Time.between(ts_start, ts_end), Faker::Internet.url, user_ips.sample,
               { is_mobile: [true, false][rand(0..1)], location: Faker::Address.country_code },
                 cost_model == 'cost_per_click' ? rand(cpc_amount_range) : nil]
    end
  end

  puts "  -> Generated #{count} clicks" + " " * 10
end

def generate_fake_data_for_ad(ad, impression_count:, click_count:, ts_start:, ts_end:)
  user_ips = impression_count.times.map { Faker::Internet.ip_v4_address }

  generate_fake_impressions(ad.id, impression_count, user_ips, ts_start, ts_end, ad.campaign.cost_model)
  generate_fake_clicks(ad.id, click_count, user_ips, ts_start, ts_end, ad.campaign.cost_model)

  # Update counter cache and touch manually since we're using COPY
  ad.update! impressions_count: ad.impressions_count + impression_count,
             clicks_count: ad.clicks_count + click_count,
             updated_at: Time.now
end

namespace :test_data do
  desc 'Loads fake test data in bulk (one time, will exit when done)'
  task load_bulk: :environment do
    ts_start = 6.months.ago
    ts_end   = Time.now

    account_count_range    = 2..2 #100..100
    campaign_count_range   = 2..15
    ad_count_range         = 3..5
    impression_count_range = 50_000..500_000
    click_count_range      = 1..50_000

    rand(account_count_range).times do
      puts ''

      account = Account.create! name: Faker::Name.name, email: Faker::Internet.email, password: Faker::Internet.password, image_url: Faker::Avatar.image

      rand(campaign_count_range).times do
        campaign = account.campaigns.create! name: Faker::Superhero.name,
                                             cost_model: ['cost_per_click', 'cost_per_impression'][rand(0..1)],
                                             state: ['paused', 'running', 'archived'][rand(0..2)]

        puts "Campaign ##{campaign.id}"

        domain_name = Faker::Internet.domain_name

        rand(ad_count_range).times do

          ad = campaign.ads.create! name: Faker::Superhero.power, image_url: Faker::Placeholdit.image("600x100"),
                                    target_url: Faker::Internet.url(domain_name)

          puts "  Ad ##{ad.id}"

          generate_fake_data_for_ad ad,
                                    impression_count: rand(impression_count_range),
                                    click_count: rand(click_count_range),
                                    ts_start: ts_start,
                                    ts_end: ts_end
        end
      end
    end
  end

  desc 'Loads fake test data continuously (won\'t exit until aborted by user)'
  task :load_realtime => :environment do
    impression_count_range = 2..20
    click_count_range      = 0..2

    # Simulate that we receive data in batches of 60 seconds
    loop do
      ts_start = 60.seconds.ago
      ts_end   = Time.now

      Ad.all.each do |ad|
        next if ad.campaign.state != 'running'

        print 'A'
        generate_fake_data_for_ad ad,
                                  impression_count: rand(impression_count_range),
                                  click_count: rand(click_count_range),
                                  ts_start: ts_start,
                                  ts_end: ts_end
      end

      puts "\n"

      time_until_next = (ts_end + 60.seconds - Time.now).to_i
      puts format("Sleeping for %d seconds", time_until_next)
      sleep time_until_next if time_until_next > 0
    end
  end
end
