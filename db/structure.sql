SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
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
-- Name: citus_columnar; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citus_columnar WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION citus_columnar; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citus_columnar IS 'Citus Columnar extension';


--
-- Name: campaign_cost_model; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.campaign_cost_model AS ENUM (
    'cost_per_click',
    'cost_per_impression'
);


--
-- Name: campaign_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.campaign_state AS ENUM (
    'paused',
    'running',
    'archived'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ads (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    target_url text NOT NULL,
    impressions_count bigint DEFAULT 0 NOT NULL,
    clicks_count bigint DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ads_id_seq OWNED BY public.ads.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name text NOT NULL,
    cost_model public.campaign_cost_model NOT NULL,
    state public.campaign_state NOT NULL,
    monthly_budget integer,
    blacklisted_site_urls character varying[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaigns_id_seq OWNED BY public.campaigns.id;


--
-- Name: click_daily_rollups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.click_daily_rollups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id bigint NOT NULL,
    ad_id bigint NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);


--
-- Name: clicks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clicks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id bigint NOT NULL,
    ad_id bigint NOT NULL,
    clicked_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_click_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: impression_daily_rollups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impression_daily_rollups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id bigint NOT NULL,
    ad_id bigint NOT NULL,
    count bigint NOT NULL,
    date date NOT NULL
);


--
-- Name: impressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impressions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id bigint NOT NULL,
    ad_id bigint NOT NULL,
    seen_at timestamp without time zone NOT NULL,
    site_url text NOT NULL,
    cost_per_impression_usd numeric(20,10),
    user_ip inet NOT NULL,
    user_data jsonb NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    encrypted_password text NOT NULL,
    email text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: ads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads ALTER COLUMN id SET DEFAULT nextval('public.ads_id_seq'::regclass);


--
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN id SET DEFAULT nextval('public.campaigns_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ads ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (company_id, id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (company_id, id);


--
-- Name: click_daily_rollups click_daily_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.click_daily_rollups
    ADD CONSTRAINT click_daily_rollups_pkey PRIMARY KEY (company_id, id);


--
-- Name: clicks clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clicks
    ADD CONSTRAINT clicks_pkey PRIMARY KEY (company_id, id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: impression_daily_rollups impression_daily_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impression_daily_rollups
    ADD CONSTRAINT impression_daily_rollups_pkey PRIMARY KEY (company_id, id);


--
-- Name: impressions impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressions
    ADD CONSTRAINT impressions_pkey PRIMARY KEY (company_id, id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_ads_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ads_on_campaign_id ON public.ads USING btree (campaign_id);


--
-- Name: index_ads_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ads_on_company_id ON public.ads USING btree (company_id);


--
-- Name: index_campaigns_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_company_id ON public.campaigns USING btree (company_id);


--
-- Name: index_click_daily_rollups_on_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_click_daily_rollups_on_ad_id ON public.click_daily_rollups USING btree (ad_id);


--
-- Name: index_click_daily_rollups_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_click_daily_rollups_on_company_id ON public.click_daily_rollups USING btree (company_id);


--
-- Name: index_clicks_on_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clicks_on_ad_id ON public.clicks USING btree (ad_id);


--
-- Name: index_clicks_on_clicked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clicks_on_clicked_at ON public.clicks USING btree (clicked_at);


--
-- Name: index_clicks_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clicks_on_company_id ON public.clicks USING btree (company_id);


--
-- Name: index_impression_daily_rollups_on_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impression_daily_rollups_on_ad_id ON public.impression_daily_rollups USING btree (ad_id);


--
-- Name: index_impression_daily_rollups_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impression_daily_rollups_on_company_id ON public.impression_daily_rollups USING btree (company_id);


--
-- Name: index_impressions_on_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impressions_on_ad_id ON public.impressions USING btree (ad_id);


--
-- Name: index_impressions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impressions_on_company_id ON public.impressions USING btree (company_id);


--
-- Name: index_impressions_on_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impressions_on_seen_at ON public.impressions USING btree (seen_at);


--
-- Name: index_users_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_company_id ON public.users USING btree (company_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160523211642'),
('20160622202229');


