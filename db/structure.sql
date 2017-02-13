
-- PostgreSQL database dump

SET statement_timeout = 0;
SET lock_timeout = 0;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- Name: citus; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS citus WITH SCHEMA pg_catalog;

-- Name: EXTENSION citus; Type: COMMENT

COMMENT ON EXTENSION citus IS 'Citus distributed database';

-- Name: plpgsql; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

-- Name: EXTENSION plpgsql; Type: COMMENT

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

-- Name: btree_gin; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;

-- Name: EXTENSION btree_gin; Type: COMMENT

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';

-- Name: btree_gist; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;

-- Name: EXTENSION btree_gist; Type: COMMENT

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';

-- Name: citext; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;

-- Name: EXTENSION citext; Type: COMMENT

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';

-- Name: cube; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;

-- Name: EXTENSION cube; Type: COMMENT

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';

-- Name: dblink; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;

-- Name: EXTENSION dblink; Type: COMMENT

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';

-- Name: earthdistance; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;

-- Name: EXTENSION earthdistance; Type: COMMENT

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';

-- Name: hll; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS hll WITH SCHEMA public;

-- Name: EXTENSION hll; Type: COMMENT

COMMENT ON EXTENSION hll IS 'type for storing hyperloglog data';

-- Name: hstore; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;

-- Name: EXTENSION hstore; Type: COMMENT

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';

-- Name: intarray; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;

-- Name: EXTENSION intarray; Type: COMMENT

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';

-- Name: pg_prewarm; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS pg_prewarm WITH SCHEMA public;

-- Name: EXTENSION pg_prewarm; Type: COMMENT

COMMENT ON EXTENSION pg_prewarm IS 'prewarm relation data';

-- Name: pg_trgm; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

-- Name: EXTENSION pg_trgm; Type: COMMENT

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';

-- Name: pgcrypto; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- Name: EXTENSION pgcrypto; Type: COMMENT

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';

-- Name: session_analytics; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS session_analytics WITH SCHEMA public;

-- Name: shard_rebalancer; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS shard_rebalancer WITH SCHEMA public;

-- Name: sslinfo; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS sslinfo WITH SCHEMA public;

-- Name: EXTENSION sslinfo; Type: COMMENT

COMMENT ON EXTENSION sslinfo IS 'information about SSL certificates';

-- Name: unaccent; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;

-- Name: EXTENSION unaccent; Type: COMMENT

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';

-- Name: uuid-ossp; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Name: EXTENSION "uuid-ossp"; Type: COMMENT

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';

-- Name: xml2; Type: EXTENSION

CREATE EXTENSION IF NOT EXISTS xml2 WITH SCHEMA public;

-- Name: EXTENSION xml2; Type: COMMENT

COMMENT ON EXTENSION xml2 IS 'XPath querying and XSLT';

SET search_path = public, pg_catalog;

-- Name: campaign_budget_interval; Type: TYPE

CREATE TYPE campaign_budget_interval AS ENUM (
    'daily',
    'weekly',
    'monthly'
);

-- Name: campaign_cost_model; Type: TYPE

CREATE TYPE campaign_cost_model AS ENUM (
    'cost_per_click',
    'cost_per_impression'
);

-- Name: campaign_state; Type: TYPE

CREATE TYPE campaign_state AS ENUM (
    'paused',
    'running',
    'archived'
);

-- Name: colocation_placement_type; Type: TYPE

CREATE TYPE colocation_placement_type AS (
	shardid1 bigint,
	shardid2 bigint,
	nodename text,
	nodeport bigint
);

-- Name: citus_run_on_all_colocated_placements(regclass, regclass, text, boolean); Type: FUNCTION

CREATE FUNCTION citus_run_on_all_colocated_placements(table_name1 regclass, table_name2 regclass, command text, parallel boolean DEFAULT true, OUT nodename text, OUT nodeport integer, OUT shardid1 bigint, OUT shardid2 bigint, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
	workers text[];
	ports int[];
	shards1 bigint[];
	shards2 bigint[];
	commands text[];
BEGIN
	IF NOT (SELECT citus_tables_colocated(table_name1, table_name2)) THEN
		RAISE EXCEPTION 'tables % and % are not co-located', table_name1, table_name2;
	END IF;

	WITH active_shard_placements AS (
		SELECT
			ds.logicalrelid,
			ds.shardid AS shardid,
			shard_name(ds.logicalrelid, ds.shardid) AS shardname,
			ds.shardminvalue AS shardminvalue,
			ds.shardmaxvalue AS shardmaxvalue,
			dsp.nodename AS nodename,
			dsp.nodeport::int AS nodeport
		FROM pg_dist_shard ds JOIN pg_dist_shard_placement dsp USING (shardid)
		WHERE dsp.shardstate = 1 and (ds.logicalrelid::regclass = table_name1 or
			ds.logicalrelid::regclass = table_name2)
		ORDER BY ds.logicalrelid, ds.shardid, dsp.nodename, dsp.nodeport),
	citus_colocated_placements AS (
		SELECT
			a.logicalrelid::regclass AS tablename1,
			a.shardid AS shardid1,
			shard_name(a.logicalrelid, a.shardid) AS shardname1,
			b.logicalrelid::regclass AS tablename2,
			b.shardid AS shardid2,
			shard_name(b.logicalrelid, b.shardid) AS shardname2,
			a.nodename AS nodename,
			a.nodeport::int AS nodeport
		FROM
			active_shard_placements a, active_shard_placements b
		WHERE
			a.shardminvalue = b.shardminvalue AND
			a.shardmaxvalue = b.shardmaxvalue AND
			a.logicalrelid != b.logicalrelid AND
			a.nodename = b.nodename AND
			a.nodeport = b.nodeport AND
			a.logicalrelid::regclass = table_name1 AND
			b.logicalrelid::regclass = table_name2
		ORDER BY a.logicalrelid, a.shardid, nodename, nodeport)
	SELECT
		array_agg(cp.nodename), array_agg(cp.nodeport), array_agg(cp.shardid1),
		array_agg(cp.shardid2), array_agg(format(command, cp.shardname1, cp.shardname2))
	INTO workers, ports, shards1, shards2, commands
  	FROM citus_colocated_placements cp;

	RETURN QUERY SELECT r.node_name, r.node_port, shards1[ordinality],
		shards2[ordinality], r.success, r.result
	FROM master_run_on_worker(workers, ports, commands, parallel) WITH ORDINALITY r;
END;
$$;

-- Name: citus_run_on_all_placements(regclass, text, boolean); Type: FUNCTION

CREATE FUNCTION citus_run_on_all_placements(table_name regclass, command text, parallel boolean DEFAULT true, OUT nodename text, OUT nodeport integer, OUT shardid bigint, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
	workers text[];
	ports int[];
	shards bigint[];
	commands text[];
BEGIN
	WITH citus_placements AS (
		SELECT
			ds.logicalrelid::regclass AS tablename,
			ds.shardid AS shardid,
			shard_name(ds.logicalrelid, ds.shardid) AS shardname,
			dsp.nodename AS nodename, dsp.nodeport::int AS nodeport
		FROM pg_dist_shard ds JOIN pg_dist_shard_placement dsp USING (shardid)
		WHERE dsp.shardstate = 1 and ds.logicalrelid::regclass = table_name
		ORDER BY ds.logicalrelid, ds.shardid, dsp.nodename, dsp.nodeport)
	SELECT
		array_agg(cp.nodename), array_agg(cp.nodeport), array_agg(cp.shardid),
		array_agg(format(command, cp.shardname))
	INTO workers, ports, shards, commands
	FROM citus_placements cp;

	RETURN QUERY
		SELECT r.node_name, r.node_port, shards[ordinality],
			r.success, r.result
		FROM master_run_on_worker(workers, ports, commands, parallel) WITH ORDINALITY r;
END;
$$;

-- Name: citus_run_on_all_shards(regclass, text, boolean); Type: FUNCTION

CREATE FUNCTION citus_run_on_all_shards(table_name regclass, command text, parallel boolean DEFAULT true, OUT shardid bigint, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
	workers text[];
	ports int[];
	shards bigint[];
	commands text[];
	shard_count int;
BEGIN
	SELECT COUNT(*) INTO shard_count FROM pg_dist_shard
	WHERE logicalrelid = table_name;

	WITH citus_shards AS (
		SELECT ds.logicalrelid::regclass AS tablename,
			ds.shardid AS shardid,
			shard_name(ds.logicalrelid, ds.shardid) AS shardname,
			array_agg(dsp.nodename) AS nodenames,
			array_agg(dsp.nodeport) AS nodeports
		FROM pg_dist_shard ds LEFT JOIN pg_dist_shard_placement dsp USING (shardid)
		WHERE dsp.shardstate = 1 and ds.logicalrelid::regclass = table_name
		GROUP BY ds.logicalrelid, ds.shardid
		ORDER BY ds.logicalrelid, ds.shardid)
	SELECT
		array_agg(cs.nodenames[1]), array_agg(cs.nodeports[1]), array_agg(cs.shardid),
		array_agg(format(command, cs.shardname))
	INTO workers, ports, shards, commands
	FROM citus_shards cs;

	IF (shard_count != array_length(workers, 1)) THEN
		RAISE NOTICE 'some shards do  not have active placements';
	END IF;

	RETURN QUERY
		SELECT shards[ordinality], r.success, r.result
		FROM master_run_on_worker(workers, ports, commands, parallel) WITH ORDINALITY r;
END;
$$;

-- Name: citus_run_on_all_workers(text, boolean); Type: FUNCTION

CREATE FUNCTION citus_run_on_all_workers(command text, parallel boolean DEFAULT true, OUT nodename text, OUT nodeport integer, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
	workers text[];
	ports int[];
	commands text[];
BEGIN
	WITH citus_workers AS (
		SELECT * FROM master_get_active_worker_nodes() ORDER BY node_name, node_port)
	SELECT array_agg(node_name), array_agg(node_port), array_agg(command)
	INTO workers, ports, commands
	FROM citus_workers;

	RETURN QUERY SELECT * FROM master_run_on_worker(workers, ports, commands, parallel);
END;
$$;

-- Name: citus_tables_colocated(regclass, regclass); Type: FUNCTION

CREATE FUNCTION citus_tables_colocated(table1 regclass, table2 regclass) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	colocated_shard_count int;
	table1_shard_count int;
	table2_shard_count int;
	table1_placement_count int;
	table2_placement_count int;
	table1_placements colocation_placement_type[];
	table2_placements colocation_placement_type[];
BEGIN
	SELECT count(*),
	    (SELECT count(*) FROM pg_dist_shard a WHERE a.logicalrelid = table1),
	    (SELECT count(*) FROM pg_dist_shard b WHERE b.logicalrelid = table2)
	INTO colocated_shard_count, table1_shard_count, table2_shard_count
	FROM pg_dist_shard tba JOIN pg_dist_shard tbb USING(shardminvalue, shardmaxvalue)
	WHERE tba.logicalrelid = table1 AND tbb.logicalrelid = table2;

	IF (table1_shard_count != table2_shard_count OR
		table1_shard_count != colocated_shard_count)
	THEN
		RETURN false;
	END IF;

	WITH colocated_shards AS (
		SELECT tba.shardid as shardid1, tbb.shardid as shardid2
		FROM pg_dist_shard tba JOIN pg_dist_shard tbb USING(shardminvalue, shardmaxvalue)
		WHERE tba.logicalrelid = table1 AND tbb.logicalrelid = table2),
	left_shard_placements AS (
		SELECT cs.shardid1, cs.shardid2, sp.nodename, sp.nodeport
		FROM colocated_shards cs JOIN pg_dist_shard_placement sp ON (cs.shardid1 = sp.shardid)
		WHERE sp.shardstate = 1)
	SELECT
		array_agg((lsp.shardid1, lsp.shardid2, lsp.nodename, lsp.nodeport)::colocation_placement_type
			ORDER BY shardid1, shardid2, nodename, nodeport),
		count(distinct lsp.shardid1)
	FROM left_shard_placements lsp
	INTO table1_placements, table1_placement_count;

	WITH colocated_shards AS (
		SELECT tba.shardid as shardid1, tbb.shardid as shardid2
		FROM pg_dist_shard tba JOIN pg_dist_shard tbb USING(shardminvalue, shardmaxvalue)
		WHERE tba.logicalrelid = table1 AND tbb.logicalrelid = table2),
	right_shard_placements AS (
		SELECT cs.shardid1, cs.shardid2, sp.nodename, sp.nodeport
		FROM colocated_shards cs LEFT JOIN pg_dist_shard_placement sp ON(cs.shardid2 = sp.shardid)
		WHERE sp.shardstate = 1)
	SELECT
		array_agg((rsp.shardid1, rsp.shardid2, rsp.nodename, rsp.nodeport)::colocation_placement_type
			ORDER BY shardid1, shardid2, nodename, nodeport),
		count(distinct rsp.shardid2)
	FROM right_shard_placements rsp
	INTO table2_placements, table2_placement_count;

	IF (table1_shard_count != table1_placement_count
		OR table1_placement_count != table2_placement_count) THEN
		RETURN false;
	END IF;

	IF (array_length(table1_placements, 1) != array_length(table2_placements, 1)) THEN
		RETURN false;
	END IF;

	FOR i IN  1..array_length(table1_placements,1) LOOP
		IF (table1_placements[i].nodename != table2_placements[i].nodename OR
			table1_placements[i].nodeport != table2_placements[i].nodeport) THEN
			RETURN false;
		END IF;
	END LOOP;

	RETURN true;
END;
$$;

-- Name: master_run_on_worker(text[], integer[], text[], boolean); Type: FUNCTION

CREATE FUNCTION master_run_on_worker(worker_name text[], port integer[], command text[], parallel boolean, OUT node_name text, OUT node_port integer, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE c STABLE STRICT
    AS 'citus.so', 'master_run_on_worker';

SET default_tablespace = '';

SET default_with_oids = false;

-- Name: accounts; Type: TABLE

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name text NOT NULL,
    image_url text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

-- Name: ads; Type: TABLE

CREATE TABLE ads (
    id SERIAL PRIMARY KEY,
    account_id integer NOT NULL,
    campaign_id integer NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    target_url text NOT NULL,
    impressions_count bigint DEFAULT 0 NOT NULL,
    clicks_count bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

-- Name: campaigns; Type: TABLE

CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    account_id integer NOT NULL,
    name text NOT NULL,
    cost_model campaign_cost_model NOT NULL,
    state campaign_state NOT NULL,
    budget_interval campaign_budget_interval,
    budget integer,
    blacklisted_site_urls character varying[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

-- Name: click_daily_rollups; Type: TABLE

CREATE TABLE click_daily_rollups (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    account_id integer NOT NULL,
    ad_id integer NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);

-- Name: clicks; Type: TABLE

CREATE TABLE clicks (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    account_id integer NOT NULL,
    ad_id integer NOT NULL,
    clicked_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_click_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);

-- Name: impression_daily_rollups; Type: TABLE

CREATE TABLE impression_daily_rollups (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    account_id integer NOT NULL,
    ad_id integer NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);

-- Name: impressions; Type: TABLE

CREATE TABLE impressions (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    account_id integer NOT NULL,
    ad_id integer NOT NULL,
    seen_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_impression_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);

-- Name: schema_migrations; Type: TABLE

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);

-- Name: users; Type: TABLE

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    account_id integer NOT NULL,
    encrypted_password text NOT NULL,
    email text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id, account_id);

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id, account_id);

ALTER TABLE ONLY click_daily_rollups
    ADD CONSTRAINT click_daily_rollups_pkey PRIMARY KEY (id, account_id);

ALTER TABLE ONLY clicks
    ADD CONSTRAINT clicks_pkey PRIMARY KEY (id, account_id);

ALTER TABLE ONLY impression_daily_rollups
    ADD CONSTRAINT impression_daily_rollups_pkey PRIMARY KEY (id, account_id);

ALTER TABLE ONLY impressions
    ADD CONSTRAINT impressions_pkey PRIMARY KEY (id, account_id);

-- Name: index_clicks_on_clicked_at; Type: INDEX

CREATE INDEX index_clicks_on_clicked_at ON clicks USING btree (clicked_at);

-- Name: index_impressions_on_seen_at; Type: INDEX

CREATE INDEX index_impressions_on_seen_at ON impressions USING btree (seen_at);

-- Name: unique_schema_migrations; Type: INDEX

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);

-- PostgreSQL database dump complete

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160523211642');
INSERT INTO schema_migrations (version) VALUES ('20160622202229');
