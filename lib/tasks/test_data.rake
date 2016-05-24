namespace :test_data do
  desc 'Loads fake test data in bulk (one time, will exit when done)'
  task load_bulk: :environment do
    ts_start = 6.months.ago
    ts_end   = Time.now

    account_count_range    = 1..1 #100..100
    campaign_count_range   = 1..15
    ad_count_range         = 1..5
    impression_count_range = 50_000..500_000
    click_count_range      = 1..50_000
    cpi_amount_range       = rand(0.001..0.01)
    cpc_amount_range       = rand(1.0..5.0)

    rand(account_count_range).times do
      puts ''

      account = Account.create! email: Faker::Internet.email, password: Faker::Internet.password

      rand(campaign_count_range).times do
        print 'C'

        campaign = Campaign.create! account: account, name: Faker::Superhero.name,
                                    cost_model: ['cost_per_click', 'cost_per_impression'][rand(0..1)],
                                    state: ['paused', 'running', 'archived'][rand(0..2)]

        domain_name = Faker::Internet.domain_name

        rand(ad_count_range).times do
          print 'A'

          ad_id = SecureRandom.uuid
          ad = Ad.create! id: ad_id, name: Faker::Hipster.sentence(3), image_url: Faker::Placeholdit.image("600x100"),
                          target_url: Faker::Internet.url(domain_name), campaign: campaign

          impression_count = rand(impression_count_range)
          user_ips = impression_count.times.map { Faker::Internet.ip_v4_address }

          impression_count.times do |impression_num|
            print 'I'
            Impression.create! id: SecureRandom.uuid, ad_id: ad_id, seen_at: Faker::Time.between(ts_start, ts_end), site_url: Faker::Internet.url,
                               user_ip: user_ips[impression_num], user_data: { is_mobile: [true, false][rand(0..1)], location: Faker::Address.country_code },
                               cost_per_impression_usd: campaign.cost_model == 'cost_per_impression' ? rand(cpi_amount_range) : nil
          end

          rand(click_count_range).times do
            print 'C'
            Click.create! id: SecureRandom.uuid, ad_id: ad_id, clicked_at: Faker::Time.between(ts_start, ts_end), site_url: Faker::Internet.url,
                          user_ip: user_ips.sample, user_data: { is_mobile: [true, false][rand(0..1)], location: Faker::Address.country_code },
                          cost_per_click_usd: campaign.cost_model == 'cost_per_click' ? rand(cpc_amount_range) : nil
          end
        end
      end
    end
  end

  desc 'Loads fake test data continuously (won\'t exit until aborted by user)'
  task :load_realtime => :environment do

  end
end
