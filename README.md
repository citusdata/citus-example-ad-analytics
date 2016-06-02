## Citus Example: Ad Analytics

This is a work in progress, but feel free to explore the codebase!

You can see the deployed version at http://citus-example-ad-analytics.herokuapp.com/

## Schema Diagram

<img src="http://cl.ly/0n3G0Q453p1X/schema_diagram.png" width="600" />

We're distributing only the part of our dataset that we expect to take significant amounts of space, specifically
`ads`, `clicks` and `impressions` (marked with 🦄).

We use `ad_id` as the common shard key for the hash distribution, in order to have data for a specific ad colocated on one shard.
