--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgres; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


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
    id integer NOT NULL,
    campaign_id integer NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    target_url text NOT NULL,
    impressions_count bigint DEFAULT 0 NOT NULL,
    clicks_count bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_id_seq OWNED BY ads.id;


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
-- Name: click_daily_rollups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE click_daily_rollups (
    ad_id integer NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);


--
-- Name: clicks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE clicks (
    click_id uuid DEFAULT uuid_generate_v4() NOT NULL,
    ad_id integer NOT NULL,
    clicked_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_click_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);


--
-- Name: impression_daily_rollups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE impression_daily_rollups (
    ad_id integer NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);


--
-- Name: impressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE impressions (
    impression_id uuid DEFAULT uuid_generate_v4() NOT NULL,
    ad_id integer NOT NULL,
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

ALTER TABLE ONLY ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);


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
-- Name: ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: click_daily_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY click_daily_rollups
    ADD CONSTRAINT click_daily_rollups_pkey PRIMARY KEY (ad_id, date);


--
-- Name: clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clicks
    ADD CONSTRAINT clicks_pkey PRIMARY KEY (click_id, ad_id);


--
-- Name: impression_daily_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY impression_daily_rollups
    ADD CONSTRAINT impression_daily_rollups_pkey PRIMARY KEY (ad_id, date);


--
-- Name: impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY impressions
    ADD CONSTRAINT impressions_pkey PRIMARY KEY (impression_id, ad_id);


--
-- Name: clicks_clicked_at_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX clicks_clicked_at_brin ON clicks USING brin (clicked_at);


--
-- Name: impressions_seen_at_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX impressions_seen_at_brin ON impressions USING brin (seen_at);


--
-- Name: index_ads_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ads_on_campaign_id ON ads USING btree (campaign_id);


--
-- Name: index_campaigns_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_account_id ON campaigns USING btree (account_id);


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

INSERT INTO schema_migrations (version) VALUES ('20160622202229');

