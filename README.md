## Citus Example: Ad Analytics

Example app that uses the distributed Citus database to provide a realtime ad analytics dashboard.

## Deploying on Citus Cloud and Heroku

1. Migrate the database locally: `rake db:migrate`
2. Load the test data into the database: `rake test_data:load_bulk`
3. Load the summary data into the database: `rake rollup:initial`
4. Run the app locally: `rails s -b 0.0.0.0 -p 3000`

After starting the data load task visit the app to see an example of what you can build with Citus.

Note: If you get an error like "could not find the source blob" on Heroku deploy, just click the Deploy button again.

## Screenshots

<img src="http://cl.ly/0y430z3l122y/Screen%20Shot%202016-06-01%20at%206.15.02%20PM.png" width="600" />

## Schema Diagram

<img src="http://cl.ly/0n3G0Q453p1X/schema_diagram.png" width="600" />

We're distributing only the part of our dataset that we expect to take significant amounts of space, specifically
`ads`, `clicks` and `impressions`.

We use `ad_id` as the common shard key for the hash distribution, in order to have data for a specific ad colocated on one shard.

## Feature Highlight: Colocated Joins

> To join two large tables efficiently, it is advised that you distribute them on the same columns you used to join the tables. In this case, the Citus master knows which shards of the tables might match with shards of the other table by looking at the distribution column metadata. This allows Citus to prune away shard pairs which cannot produce matching join keys. The joins between remaining shard pairs are executed in parallel on the workers and then the results are returned to the master.
<br>https://www.citusdata.com/docs/citus/5.1/dist_tables/querying.html#colocated-joins

In this demo app we're showing co-located joins between the `ads` table and the `impressions` and `clicks` tables. One example query:

```sql
SELECT ads.campaign_id, COUNT(*)
  FROM ads
       JOIN impressions ON (ads.id = ad_id)
 WHERE ads.campaign_id IN (1,2,3,4,5,6,7,8,9,10,11)
 GROUP BY ads.campaign_id
```

Another example co-located join we use is to find the data for the daily click-through-rate graph on e.g. http://citus-example-ad-analytics.herokuapp.com/campaigns/1 - which uses the roll-up tables and looks like this:

<img src="http://cl.ly/1u1P2o0x1D2W/Screen%20Shot%202016-06-23%20at%205.49.26%20PM.png" />

```sql
SELECT ads.name,
           extract(epoch from idr.date) AS day,
           CASE WHEN idr.count > 0 THEN COALESCE(cdr.count, 0) / idr.count::float
           ELSE NULL
           END AS ctr
      FROM ads
           JOIN impression_daily_rollups idr ON (idr.ad_id = ads.id)
           JOIN click_daily_rollups cdr ON (idr.ad_id = cdr.ad_id AND idr.date = cdr.date)
     WHERE ads.campaign_id = 2 AND idr.date BETWEEN '2016-05-25 00:00:00 UTC' AND '2016-06-24 23:59:59 UTC'
     ORDER BY 2
```

## Feature Highlight: Daily Rollups

This demo app also shows how to work with historic data effectively. Since our impressions/clicks data is append-only, we can make a few optimizations for all data that is older than the current day.

Specifically, we can roll-up the data into daily count values, so we avoid having to read the entire table when we want to find the total amount of clicks for a given ad or campaign.

```
citus=> \d impression_daily_rollups
Table "public.impression_daily_rollups"
 Column |  Type  | Modifiers
--------+--------+-----------
 ad_id  | uuid   | not null
 count  | bigint | not null
 date   | date   | not null
Indexes:
    "impression_daily_rollups_pkey" PRIMARY KEY, btree (ad_id, date)

citus=> \d click_daily_rollups
Table "public.click_daily_rollups"
 Column |  Type  | Modifiers
--------+--------+-----------
 ad_id  | uuid   | not null
 count  | bigint | not null
 date   | date   | not null
Indexes:
    "click_daily_rollups_pkey" PRIMARY KEY, btree (ad_id, date)
```

You can see the task that runs daily here: https://github.com/citusdata/citus-example-ad-analytics/blob/master/lib/tasks/rollup.rake#L24

## Feature Highlight: Single-node transactions

With Citus you can use transactions in your code, as long as they only touch a single node. This can also be used to update multiple tables which are co-located.

In this app this is used to allow Rails' `counter_cache: true` and `touch: true` to update the parent record correctly.

Example:

```
irb(main):003:0> impression.destroy
BEGIN
DELETE FROM "impressions" WHERE "impressions"."impression_id" = 'fffff511-7012-4c5e-8431-5f97efd72926' AND "impressions"."ad_id" = '7fc94c84-f39f-4c7d-bf9e-bdbf5211a2f9'
SELECT  "ads".* FROM "ads" WHERE "ads"."id" = '7fc94c84-f39f-4c7d-bf9e-bdbf5211a2f9' LIMIT 1
UPDATE "ads" SET "impressions_count" = COALESCE("impressions_count", 0) - 1 WHERE "ads"."id" = '7fc94c84-f39f-4c7d-bf9e-bdbf5211a2f9'
UPDATE "ads" SET "updated_at" = '2016-07-22 23:52:59.667746' WHERE "ads"."id" = '7fc94c84-f39f-4c7d-bf9e-bdbf5211a2f9'
COMMIT
```

## Feature Highlight: BRIN indices to find recent data

In order to also include recent data into count values that are displayed, we're using a [BRIN index](https://www.postgresql.org/docs/9.5/static/brin-intro.html) on `impressions.seen_at` and `clicks.clicked_at` to quickly find the recent records which are not contained in the roll-up tables yet.

You can see an example query on the campaign index and detail pages, e.g.

```sql
SELECT ad_id, COUNT(*)
         FROM ads
         JOIN clicks ON (ads.id = ad_id)
        WHERE ads.campaign_id = 1
              AND clicked_at > now()::date
        GROUP BY ad_id
```

The distributed EXPLAIN output for this query shows how it uses the lossy BRIN index to find the values on the worker nodes:

```
                                                                             QUERY PLAN                                                                             
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Distributed Query into pg_merge_job_6969
   Executor: Real-Time
   Task Count: 16
   Tasks Shown: One of 16
   ->  Task
         Node: host=ec2-52-1-243-13.compute-1.amazonaws.com port=5432 dbname=citus
         ->  HashAggregate  (cost=456.49..456.50 rows=1 width=16) (actual time=0.660..0.660 rows=0 loops=1)
               Group Key: clicks.ad_id
               ->  Nested Loop  (cost=12.91..456.48 rows=2 width=16) (actual time=0.658..0.658 rows=0 loops=1)
                     Join Filter: (ads.id = clicks.ad_id)
                     Rows Removed by Join Filter: 970
                     ->  Seq Scan on ads_102137 ads  (cost=0.00..1.64 rows=1 width=16) (actual time=0.009..0.013 rows=1 loops=1)
                           Filter: (campaign_id = 6)
                           Rows Removed by Filter: 50
                     ->  Bitmap Heap Scan on clicks_102169 clicks  (cost=12.91..453.39 rows=116 width=16) (actual time=0.100..0.459 rows=970 loops=1)
                           Recheck Cond: (clicked_at > (now())::date)
                           Rows Removed by Index Recheck: 48
                           Heap Blocks: lossy=19
                           ->  Bitmap Index Scan on clicks_clicked_at_brin_102169  (cost=0.00..12.88 rows=116 width=0) (actual time=0.083..0.083 rows=1280 loops=1)
                                 Index Cond: (clicked_at > (now())::date)
             Planning time: 0.484 ms
             Execution time: 0.753 ms
 Master Query
   ->  HashAggregate  (cost=0.00..0.15 rows=10 width=0) (actual time=0.001..0.001 rows=0 loops=1)
         Group Key: intermediate_column_6969_0
         ->  Seq Scan on pg_merge_job_6969  (cost=0.00..0.00 rows=0 width=0) (actual time=0.001..0.001 rows=0 loops=1)
 Planning time: 7.291 ms
(28 rows)
```

## LICENSE

Copyright (c) 2016, Citus Data Inc

Licensed under the MIT license - feel free to incorporate the code in your own projects!
