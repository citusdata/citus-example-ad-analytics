--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
-- Name: ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ads (
    id integer NOT NULL,
    company_id integer NOT NULL,
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
    company_id integer NOT NULL,
    name text NOT NULL,
    cost_model campaign_cost_model NOT NULL,
    state campaign_state NOT NULL,
    monthly_budget integer,
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
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    company_id integer NOT NULL,
    ad_id integer NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);


--
-- Name: clicks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE clicks (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    company_id integer NOT NULL,
    ad_id integer NOT NULL,
    clicked_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_click_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE companies (
    id integer NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE companies_id_seq OWNED BY companies.id;


--
-- Name: impression_daily_rollups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE impression_daily_rollups (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    company_id integer NOT NULL,
    ad_id integer NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);


--
-- Name: impressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE impressions (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    company_id integer NOT NULL,
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
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    company_id integer NOT NULL,
    encrypted_password text NOT NULL,
    email text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: ads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);


--
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns ALTER COLUMN id SET DEFAULT nextval('campaigns_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies ALTER COLUMN id SET DEFAULT nextval('companies_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: ads ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id, company_id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id, company_id);


--
-- Name: click_daily_rollups click_daily_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY click_daily_rollups
    ADD CONSTRAINT click_daily_rollups_pkey PRIMARY KEY (id, company_id);


--
-- Name: clicks clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clicks
    ADD CONSTRAINT clicks_pkey PRIMARY KEY (id, company_id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: impression_daily_rollups impression_daily_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY impression_daily_rollups
    ADD CONSTRAINT impression_daily_rollups_pkey PRIMARY KEY (id, company_id);


--
-- Name: impressions impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY impressions
    ADD CONSTRAINT impressions_pkey PRIMARY KEY (id, company_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_clicks_on_clicked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clicks_on_clicked_at ON clicks USING btree (clicked_at);


--
-- Name: index_impressions_on_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impressions_on_seen_at ON impressions USING btree (seen_at);


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

