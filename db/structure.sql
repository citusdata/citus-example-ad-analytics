--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citus; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citus WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION citus; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citus IS 'Citus distributed database';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- Name: hll; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hll WITH SCHEMA public;


--
-- Name: EXTENSION hll; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hll IS 'type for storing hyperloglog data';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: sslinfo; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS sslinfo WITH SCHEMA public;


--
-- Name: EXTENSION sslinfo; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION sslinfo IS 'information about SSL certificates';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: xml2; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS xml2 WITH SCHEMA public;


--
-- Name: EXTENSION xml2; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION xml2 IS 'XPath querying and XSLT';


SET search_path = public, pg_catalog;

--
-- Name: campaign_budget_interval; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE campaign_budget_interval AS ENUM (
    'daily',
    'weekly',
    'monthly'
);


--
-- Name: campaign_cost_model; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE campaign_cost_model AS ENUM (
    'cost_per_click',
    'cost_per_impression'
);


--
-- Name: campaign_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE campaign_state AS ENUM (
    'paused',
    'running',
    'archived'
);


--
-- Name: citus_close_dblink(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION citus_close_dblink() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM dblink_disconnect(connname)
  FROM citus_placements p JOIN unnest(dblink_get_connections()) conn ON (p.connname = conn);

  PERFORM dblink_disconnect(connname)
  FROM citus_workers w JOIN unnest(dblink_get_connections()) conn ON (w.connname = conn);
END;
$$;


--
-- Name: citus_run_on_all_placements(regclass, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION citus_run_on_all_placements(table_name regclass, command text, parallel boolean DEFAULT false, OUT nodename text, OUT nodeport integer, OUT shardid bigint, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
  placement citus_placements%rowtype;
BEGIN
  PERFORM dblink_connect(connname, connstring)
  FROM citus_placements p LEFT JOIN unnest(dblink_get_connections()) conn ON (p.connname = conn)
  WHERE tablename = table_name AND conn IS NULL;

  IF parallel THEN
    PERFORM dblink_send_query(connname, format(command, shardname, shardname, shardname))
    FROM citus_placements WHERE tablename = table_name;
  END IF;

  FOR placement IN 
    SELECT * FROM citus_placements WHERE tablename = table_name
  LOOP

    IF NOT parallel THEN 
      PERFORM dblink_send_query(placement.connname, format(command,
                                placement.shardname,
                                placement.shardname,
                                placement.shardname));
    END IF;

    LOOP
      BEGIN
        RETURN QUERY
        SELECT placement.nodename, placement.nodeport, placement.shardid, true, res
        FROM dblink_get_result(placement.connname) AS r(res text);

        EXIT WHEN NOT FOUND;
      EXCEPTION WHEN others THEN
        RETURN QUERY
        SELECT placement.nodename, placement.nodeport, placement.shardid, false, SQLERRM;
      END;
    END LOOP;

    PERFORM FROM dblink_get_result(placement.connname, false) AS r(res text);
  END LOOP;

END;
$$;


--
-- Name: citus_run_on_all_workers(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION citus_run_on_all_workers(command text, parallel boolean DEFAULT true, OUT nodename text, OUT nodeport integer, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
  worker citus_workers%rowtype;
BEGIN
  PERFORM dblink_connect(connname, connstring)
  FROM citus_workers w LEFT JOIN unnest(dblink_get_connections()) conn ON (w.connname = conn)
  WHERE conn IS NULL;

  IF parallel THEN
    PERFORM dblink_send_query(connname, command)
    FROM citus_workers;
  END IF;

  FOR worker IN
    SELECT * FROM citus_workers
  LOOP
    IF NOT parallel THEN 
      PERFORM dblink_send_query(worker.connname, command);
    END IF;

    LOOP
      BEGIN
        RETURN QUERY
        SELECT worker.nodename, worker.nodeport, true, res
        FROM dblink_get_result(worker.connname) AS r(res text);

        EXIT WHEN NOT FOUND;
      EXCEPTION WHEN others THEN
        RETURN QUERY SELECT worker.nodename, worker.nodeport, false, SQLERRM;
      END;
    END LOOP;

    PERFORM FROM dblink_get_result(worker.connname, false) AS r(res text);
  END LOOP;
END;
$$;


--
-- Name: citus_run_on_shards(regclass, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION citus_run_on_shards(table_name regclass, command text, OUT shardid bigint, OUT success boolean, OUT result text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
  shard citus_shards%rowtype;
BEGIN
  PERFORM dblink_connect(connname[1], connstring[1])
  FROM citus_shards s LEFT JOIN unnest(dblink_get_connections()) conn ON (s.connname[1] = conn)
  WHERE tablename = table_name AND conn IS NULL;

  IF parallel THEN
    PERFORM dblink_send_query(connname[1], format(command, shardname, shardname, shardname))
    FROM citus_shards WHERE tablename = table_name;
  END IF;

  FOR shard IN
    SELECT * FROM citus_shards WHERE tablename = table_name
  LOOP
    IF NOT parallel THEN
      PERFORM dblink_send_query(shard.connname[1], format(command,
                                shard.shardname,
                                shard.shardname,
                                shard.shardname));
    END IF;

    LOOP
      BEGIN
        RETURN QUERY
        SELECT shard.shardid, true, res
        FROM dblink_get_result(shard.connname[1], false) AS r(res text);

        EXIT WHEN NOT FOUND;
      EXCEPTION WHEN others THEN
        RETURN QUERY
        SELECT shard.shardid, false, SQLERRM;
      END;
    END LOOP;

    PERFORM FROM dblink_get_result(shard.connname[1], false) AS r(res text);
  END LOOP;

END;
$$;


--
-- Name: citus_shard_name(regclass, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION citus_shard_name(table_name regclass, shard_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
  SELECT table_name||'_'||shard_id;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE accounts (
    id integer NOT NULL,
    email text NOT NULL,
    encrypted_password text NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ads (
    id uuid NOT NULL,
    campaign_id integer NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    target_url text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE campaigns (
    id integer NOT NULL,
    account_id integer NOT NULL,
    name text NOT NULL,
    cost_model campaign_cost_model NOT NULL,
    state campaign_state NOT NULL,
    budget integer,
    budget_interval campaign_budget_interval,
    blacklisted_site_urls character varying[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaigns_id_seq OWNED BY campaigns.id;


--
-- Name: citus_placements; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW citus_placements AS
 SELECT (pg_dist_shard.logicalrelid)::regclass AS tablename,
    pg_dist_shard.shardid,
    citus_shard_name((pg_dist_shard.logicalrelid)::regclass, pg_dist_shard.shardid) AS shardname,
    pg_dist_shard_placement.nodename,
    (pg_dist_shard_placement.nodeport)::integer AS nodeport,
    format('%s/%s/%s'::text, pg_dist_shard_placement.nodename, pg_dist_shard_placement.nodeport, pg_dist_shard.shardid) AS connname,
    format('host=%s port=%s dbname=%s'::text, pg_dist_shard_placement.nodename, pg_dist_shard_placement.nodeport, current_database()) AS connstring
   FROM (pg_dist_shard
     JOIN pg_dist_shard_placement USING (shardid))
  WHERE (pg_dist_shard_placement.shardstate = 1)
  ORDER BY pg_dist_shard.logicalrelid, pg_dist_shard.shardid, pg_dist_shard_placement.nodename, ((pg_dist_shard_placement.nodeport)::integer);


--
-- Name: citus_shards; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW citus_shards AS
 SELECT (pg_dist_shard.logicalrelid)::regclass AS tablename,
    pg_dist_shard.shardid,
    citus_shard_name((pg_dist_shard.logicalrelid)::regclass, pg_dist_shard.shardid) AS shardname,
    array_agg(pg_dist_shard_placement.nodename) AS nodenames,
    array_agg(pg_dist_shard_placement.nodeport) AS nodeports,
    array_agg(format('%s/%s/%s'::text, pg_dist_shard_placement.nodename, pg_dist_shard_placement.nodeport, pg_dist_shard.shardid)) AS connname,
    array_agg(format('host=%s port=%s dbname=%s'::text, pg_dist_shard_placement.nodename, pg_dist_shard_placement.nodeport, current_database())) AS connstring
   FROM (pg_dist_shard
     LEFT JOIN pg_dist_shard_placement USING (shardid))
  WHERE (pg_dist_shard_placement.shardstate = 1)
  GROUP BY pg_dist_shard.logicalrelid, pg_dist_shard.shardid
  ORDER BY pg_dist_shard.logicalrelid, pg_dist_shard.shardid;


--
-- Name: citus_workers; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW citus_workers AS
 SELECT master_get_active_worker_nodes.node_name AS nodename,
    (master_get_active_worker_nodes.node_port)::integer AS nodeport,
    format('%s/%s'::text, master_get_active_worker_nodes.node_name, master_get_active_worker_nodes.node_port) AS connname,
    format('host=%s port=%s dbname=%s'::text, master_get_active_worker_nodes.node_name, master_get_active_worker_nodes.node_port, current_database()) AS connstring
   FROM master_get_active_worker_nodes() master_get_active_worker_nodes(node_name, node_port)
  ORDER BY master_get_active_worker_nodes.node_name, master_get_active_worker_nodes.node_port;


--
-- Name: clicks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE clicks (
    id uuid NOT NULL,
    ad_id uuid NOT NULL,
    clicked_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_click_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);


--
-- Name: impressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE impressions (
    id uuid NOT NULL,
    ad_id uuid NOT NULL,
    seen_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_impression_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns ALTER COLUMN id SET DEFAULT nextval('campaigns_id_seq'::regclass);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: index_clicks_on_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clicks_on_ad_id ON clicks USING btree (ad_id);


--
-- Name: index_impressions_on_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impressions_on_ad_id ON impressions USING btree (ad_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160523211642');

