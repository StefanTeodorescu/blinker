--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases
--

DROP DATABASE IF EXISTS anon;
DROP DATABASE IF EXISTS priv;




--
-- Drop roles
--

DROP ROLE IF EXISTS blinker_admin;
DROP ROLE IF EXISTS blinker_ctf;
DROP ROLE IF EXISTS blinker_web;
DROP ROLE IF EXISTS blinker_monitoring;


--
-- Roles
--

CREATE ROLE blinker_admin;
ALTER ROLE blinker_admin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE blinker_ctf;
ALTER ROLE blinker_ctf WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE blinker_web;
ALTER ROLE blinker_web WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE blinker_monitoring;
ALTER ROLE blinker_monitoring WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;





--
-- Database creation
--

CREATE DATABASE anon WITH TEMPLATE = template0 OWNER = blinker_admin;
CREATE DATABASE priv WITH TEMPLATE = template0 OWNER = blinker_admin;


\connect anon

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: ctf_challenge_state; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE ctf_challenge_state AS ENUM (
    'used',
    'current',
    'prepared'
);


ALTER TYPE ctf_challenge_state OWNER TO blinker_admin;

--
-- Name: ctf_job_status; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE ctf_job_status AS ENUM (
    'waiting',
    'inprogress',
    'completed',
    'failed'
);


ALTER TYPE ctf_job_status OWNER TO blinker_admin;

--
-- Name: ctf_job_type; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE ctf_job_type AS ENUM (
    'verify_flag',
    'generate_challenge',
    'deploy_challenge',
    'delete_deployment',
    'enforce_deadline',
    'direct_ctf'
);


ALTER TYPE ctf_job_type OWNER TO blinker_admin;

--
-- Name: deployment_state; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE deployment_state AS ENUM (
    'none',
    'initiated',
    'deploying',
    'deployed',
    'destroying',
    'destroyed',
    'failed'
);


ALTER TYPE deployment_state OWNER TO blinker_admin;

--
-- Name: event_type; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE event_type AS ENUM (
    'ctf_started',                 -- ctf_after_create
    'ctf_completed',               -- ctf_after_update
    'flag_submitted',              -- ctf_after_update
    'flag_accepted',               -- flag_verifier
    'flag_rejected',               -- flag_verifier
    'challenge_requested',         -- ctf_after_update
    'challenge_generated',         -- ctf_challenge_after_create
    'challenge_assigned',          -- ctf_after_update
    'challenge_deadline',          -- ctf_challenge_after_update
    'challenge_closed',            -- ctf_after_update
    'deployment_update',           -- challenge_deployer
    'deployment_complete',         -- ctf_challenge_after_update
    'skip_requested',              -- ctf_after_update
    'challenge_generator_failed',  -- ctf_job_after_update
    'challenge_deployer_failed'    -- ctf_job_after_update
);


ALTER TYPE event_type OWNER TO blinker_admin;

--
-- Name: experiment_kind; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE experiment_kind AS ENUM (
    'survey',
    'ctf'
);


ALTER TYPE experiment_kind OWNER TO blinker_admin;

--
-- Name: ctf_after_create(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_after_create() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN
INSERT INTO events_log (experiment,event) VALUES (NEW.uuid, 'ctf_started'::event_type);
RETURN NULL;
END;
$$;


ALTER FUNCTION public.ctf_after_create() OWNER TO blinker_admin;

--
-- Name: ctf_after_update(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_after_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

-- current_challenge
IF OLD.current_challenge IS NULL AND NEW.current_challenge IS NOT NULL
THEN
  INSERT INTO events_log (experiment, event, info, message) SELECT NEW.uuid, 'challenge_assigned'::event_type, json_build_object('challenge', NEW.current_challenge), message FROM ctf_challenges WHERE id = NEW.current_challenge;

  UPDATE ctf_challenges SET state = 'current'::ctf_challenge_state WHERE id = NEW.current_challenge;
END IF;

IF OLD.current_challenge IS NOT NULL AND NEW.current_challenge IS NULL
THEN
  INSERT INTO events_log (experiment, event, info) VALUES (NEW.uuid, 'challenge_closed'::event_type, json_build_object('challenge', OLD.current_challenge));
  UPDATE ctf_challenges SET state = 'used'::ctf_challenge_state WHERE id = OLD.current_challenge;
  INSERT INTO ctf_jobs (uuid, type) VALUES (NEW.uuid, 'direct_ctf'::ctf_job_type);
END IF;

-- challenge_requested
IF OLD.challenge_requested = false AND NEW.challenge_requested = true
THEN
  INSERT INTO events_log (experiment, event) VALUES (NEW.uuid, 'challenge_requested'::event_type);
  INSERT INTO ctf_jobs (uuid, type) VALUES (NEW.uuid, 'direct_ctf'::ctf_job_type);
END IF;

-- challenge_pending
IF OLD.challenge_pending IS NULL AND NEW.challenge_pending IS NOT NULL
THEN
  INSERT INTO ctf_jobs (uuid, type, details) VALUES (NEW.uuid, 'generate_challenge'::ctf_job_type, NEW.challenge_pending);
END IF;

-- skip_requested
IF OLD.skip_requested = false AND NEW.skip_requested = true
THEN
  INSERT INTO events_log (experiment, event) VALUES (NEW.uuid, 'skip_requested'::event_type);
  INSERT INTO ctf_jobs (uuid, type) VALUES (NEW.uuid, 'direct_ctf'::ctf_job_type);
END IF;

-- flag_submission
IF OLD.flag_submission IS NULL AND NEW.flag_submission IS NOT NULL
THEN
  INSERT INTO events_log (experiment, event, info) VALUES (NEW.uuid, 'flag_submitted'::event_type, json_build_object('flag', NEW.flag_submission));
  INSERT INTO ctf_jobs (uuid, type) VALUES (NEW.uuid, 'verify_flag'::ctf_job_type);
END IF;

-- ended_at
IF OLD.ended_at IS NULL AND NEW.ended_at IS NOT NULL
THEN
  INSERT INTO events_log (experiment, event) VALUES (NEW.uuid, 'ctf_completed'::event_type);
END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_after_update() OWNER TO blinker_admin;

--
-- Name: ctf_before_create(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_before_create() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN
NEW.current_challenge := NULL;
IF NEW.challenge_requested = true THEN RAISE 'cannot create with challenge_requested'; END IF;
NEW.challenge_requested := false;
NEW.challenge_pending := NULL;
NEW.skip_requested := false;
NEW.flag_submission := NULL;
NEW.created_at := current_timestamp;
NEW.ended_at := NULL;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_before_create() OWNER TO blinker_admin;

--
-- Name: ctf_before_update(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_before_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

-- uuid
IF OLD.uuid <> NEW.uuid THEN RAISE 'cannot change the uuid'; END IF;

-- current_challenge
IF OLD.current_challenge IS NOT NULL
  AND NEW.current_challenge IS NOT NULL
  AND OLD.current_challenge <> NEW.current_challenge
THEN
  RAISE 'cannot discard the current challenge';
END IF;

-- flag_submission
IF OLD.flag_submission IS NOT NULL
  AND NEW.flag_submission IS NOT NULL
  AND OLD.flag_submission <> NEW.flag_submission
THEN
  RAISE 'cannot discard the current flag submission';
END IF;

-- challenge_pending
IF OLD.challenge_pending IS NOT NULL
  AND NEW.challenge_pending IS NOT NULL
  AND OLD.challenge_pending <> NEW.challenge_pending
THEN
  RAISE 'cannot discard the currently pending challenge';
END IF;

IF OLD.skip_requested = true
  AND NEW.skip_requested = false
  AND NEW.current_challenge IS NOT NULL
THEN
  RAISE 'cannot unset skip_requested without unsetting current_challenge';
END IF;

-- created_at
IF OLD.created_at <> NEW.created_at THEN RAISE 'cannot change created_at'; END IF;

-- ended_at
IF OLD.ended_at IS NOT NULL
  AND (NEW.ended_at IS NULL OR OLD.ended_at <> NEW.ended_at)
THEN
  RAISE 'cannot alter ended_at';
END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_before_update() OWNER TO blinker_admin;

--
-- Name: ctf_challenge_after_create(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_challenge_after_create() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

INSERT INTO events_log (experiment, event, info) VALUES (NEW.ctf, 'challenge_generated'::event_type, json_build_object('challenge', NEW.id));
UPDATE ctfs SET challenge_pending = NULL WHERE uuid = NEW.ctf;
INSERT INTO ctf_jobs (uuid, type) VALUES (NEW.ctf, 'direct_ctf'::ctf_job_type);

RETURN NULL;
END;
$$;


ALTER FUNCTION public.ctf_challenge_after_create() OWNER TO blinker_admin;

--
-- Name: ctf_challenge_after_update(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_challenge_after_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

-- deployed_to
IF OLD.deployed_to IS NULL AND NEW.deployed_to IS NOT NULL
THEN
  INSERT INTO events_log (experiment, event, info, message) VALUES (NEW.ctf, 'deployment_complete'::event_type, json_build_object('challenge', NEW.id, 'domain', NEW.deployed_to), NEW.deployed_to);
  INSERT INTO events_log (experiment, event, info, message) VALUES (NEW.ctf, 'challenge_deadline'::event_type, json_build_object('challenge', NEW.id), (extract(epoch from NEW.deadline)::double precision * 1000)::bigint);

  INSERT INTO ctf_jobs (uuid, type, details, not_before) VALUES (NEW.ctf, 'enforce_deadline'::ctf_job_type, NEW.id, NEW.deadline);
END IF;

-- deployment_state
IF OLD.deployment_state = 'none'::deployment_state AND NEW.deployment_state = 'initiated'::deployment_state
THEN
  INSERT INTO ctf_jobs (uuid, type, details) VALUES (NEW.ctf, 'deploy_challenge'::ctf_job_type, NEW.id);
END IF;

-- state
IF (OLD.state = 'prepared' OR OLD.state = 'current') AND NEW.state = 'used' AND NEW.package IS NOT NULL
THEN
  INSERT INTO ctf_jobs (uuid, type, details) VALUES (NEW.ctf, 'delete_deployment'::ctf_job_type, NEW.id);
END IF;

RETURN NULL;
END;
$$;


ALTER FUNCTION public.ctf_challenge_after_update() OWNER TO blinker_admin;

--
-- Name: ctf_challenge_before_create(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_challenge_before_create() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

IF NEW.deployed_to IS NOT NULL THEN RAISE 'cannot have NOT NULL deployed_to'; END IF;

NEW.generated_at := current_timestamp;

RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_challenge_before_create() OWNER TO blinker_admin;

--
-- Name: ctf_challenge_before_update(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_challenge_before_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

-- id
IF OLD.id <> NEW.id THEN RAISE 'cannot change id'; END IF;

-- ctf
IF OLD.ctf <> NEW.ctf THEN RAISE 'cannot change ctf'; END IF;

-- flag
IF OLD.flag <> NEW.flag THEN RAISE 'cannot change flag'; END IF;

-- handout
IF (OLD.handout IS NULL AND NEW.handout IS NOT NULL)
  OR (OLD.handout IS NOT NULL AND NEW.handout IS NULL)
  OR (OLD.handout IS NOT NULL AND NEW.handout IS NOT NULL AND OLD.handout <> NEW.handout)
THEN
  RAISE 'cannot change handout';
END IF;

-- package
IF (OLD.package IS NULL AND NEW.package IS NOT NULL)
  OR (OLD.package IS NOT NULL AND NEW.package IS NULL)
  OR (OLD.package IS NOT NULL AND NEW.package IS NOT NULL AND OLD.package <> NEW.package)
THEN
  RAISE 'cannot change package';
END IF;

-- message
IF OLD.message <> NEW.message THEN RAISE 'cannot change message'; END IF;

-- deployed_to
IF OLD.deployed_to IS NOT NULL
  AND ((NEW.deployed_to IS NULL)
   OR (NEW.deployed_to IS NOT NULL
    AND OLD.deployed_to <> NEW.deployed_to))
THEN
  RAISE 'cannot change deployed_to';
END IF;

-- generated_at
IF OLD.generated_at <> NEW.generated_at THEN RAISE 'cannot change generated_at'; END IF;

-- deployed_at
IF OLD.deployed_at <> NEW.deployed_at THEN RAISE 'cannot change deployed_at'; END IF;
IF OLD.deployed_at IS NULL AND OLD.deployed_to IS NULL AND NEW.deployed_to IS NOT NULL
THEN
  NEW.deployed_at := now();
END IF;

-- deadline
IF OLD.deadline <> NEW.deadline THEN RAISE 'cannot change deadline'; END IF;
IF OLD.deadline IS NULL AND OLD.deployed_to IS NULL AND NEW.deployed_to IS NOT NULL
THEN
  NEW.deadline := NEW.deployed_at + interval '24 hours';
END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_challenge_before_update() OWNER TO blinker_admin;

--
-- Name: ctf_job_after_update(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_job_after_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN

CASE NEW.status
WHEN 'failed' THEN
  CASE NEW.type
  WHEN 'generate_challenge'::ctf_job_type THEN
    INSERT INTO events_log (experiment, event, info) VALUES (NEW.uuid, 'challenge_generator_failed'::event_type, json_build_object('job', NEW.id));
  WHEN 'deploy_challenge'::ctf_job_type THEN
    INSERT INTO events_log (experiment, event, info) VALUES (NEW.uuid, 'challenge_deployer_failed'::event_type, json_build_object('challenge', NEW.details, 'job', NEW.id));
  ELSE
  END CASE;
ELSE
END CASE;

NEW.id = OLD.id;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_job_after_update() OWNER TO blinker_admin;

--
-- Name: ctf_job_before_create(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

-- TODO this should handle ALL FIELDS!
CREATE FUNCTION ctf_job_before_create() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN
NEW.status := 'waiting';
NEW.added_at := current_timestamp;
NEW.started_at := NULL;
NEW.finished_at := NULL;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_job_before_create() OWNER TO blinker_admin;

--
-- Name: ctf_job_before_update(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

-- TODO this should handle ALL FIELDS!
CREATE FUNCTION ctf_job_before_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN
CASE NEW.status
WHEN 'waiting' THEN
    NEW.added_at := current_timestamp;
    NEW.started_at := NULL;
    NEW.finished_at := NULL;
WHEN 'inprogress' THEN
    NEW.added_at := OLD.added_at;
    NEW.started_at := current_timestamp;
    NEW.finished_at := NULL;
WHEN 'completed', 'failed' THEN
    NEW.added_at := OLD.added_at;
    NEW.started_at := OLD.started_at;
    NEW.finished_at := current_timestamp;
END CASE;

NEW.id = OLD.id;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_job_before_update() OWNER TO blinker_admin;

--
-- Name: ctf_jobs_notify(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_jobs_notify() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN
PERFORM pg_notify('ctf_jobs', NEW.type::text);
RETURN NEW;
END;
$$;


ALTER FUNCTION public.ctf_jobs_notify() OWNER TO blinker_admin;

--
-- Name: ctf_pick_next_challenge(uuid); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_pick_next_challenge(uuid) RETURNS character varying
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO public
    AS $_$

WITH required AS (
  SELECT challenge,
    row_number() OVER () AS normalizer
  FROM unnest(ARRAY['StaticReNormalize','StaticAmazingRop']) AS t(challenge)
  UNION
  SELECT challenge,
    NULL AS normalizer
  FROM unnest(ARRAY['SimpleBof','Refunge','HommageAIrc','Mysecuresite']) AS t(challenge)
), generated AS (
  SELECT row_number() OVER (ORDER BY id ASC) AS i,
    details AS ch_name
  FROM ctf_jobs
  WHERE uuid = $1
    AND type = 'generate_challenge'::ctf_job_type
), possibilities AS (
  SELECT CONCAT(prefix.prefix,required.challenge) AS challenge,
    COALESCE(desired.count,0) AS solvers,
    generated.ch_name IS NOT NULL AS generated_already,
    row_number() OVER (PARTITION BY required.challenge ORDER BY COALESCE(desired.count,0) ASC) = 1 AS more_needed_version,
    required.normalizer AS normalizer
  FROM required
  LEFT JOIN unnest(ARRAY['','Static']) AS prefix ON required.normalizer IS NULL
  LEFT JOIN generated ON required.challenge = generated.ch_name OR CONCAT('Static',required.challenge) = generated.ch_name
  LEFT JOIN ctf_solved AS desired ON CONCAT(prefix.prefix,required.challenge) = desired.ch_name
)
SELECT challenge FROM possibilities
WHERE more_needed_version AND NOT generated_already
ORDER BY normalizer ASC, solvers ASC, random()
LIMIT 1;

$_$;


ALTER FUNCTION public.ctf_pick_next_challenge(uuid) OWNER TO blinker_admin;

--
-- Name: ctf_stats(uuid); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION ctf_stats(uuid) RETURNS TABLE(challenge character varying, minutes integer, skipped boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO public
    AS $_$

WITH challenge_ids AS (
     SELECT row_number() over (ORDER BY id ASC) AS i,
            info->>'challenge' AS ch_id,
            happened_at AS assigned_at
     FROM events_log
     WHERE experiment = $1
           AND event = 'challenge_assigned'::event_type
     ORDER BY id ASC
     ), challenge_names AS (
     SELECT row_number() over (ORDER BY id ASC) AS i,
            details AS ch_name
     FROM ctf_jobs
     WHERE uuid = $1
           AND type = 'generate_challenge'::ctf_job_type
     ORDER BY id ASC
     ), challenge_closed AS (
     SELECT info->>'challenge' AS ch_id,
            happened_at AS at
     FROM events_log
     WHERE experiment = $1
           AND event = 'challenge_closed'::event_type
     ), challenge_skipped AS (
     SELECT happened_at AS at
     FROM events_log
     WHERE experiment = $1
           AND event = 'skip_requested'::event_type
     )
SELECT challenge_names.ch_name AS challenge,
       round(extract(epoch from (challenge_closed.at - challenge_ids.assigned_at)) / 60)::integer AS minutes,
       (SELECT COUNT(*) > 0 FROM challenge_skipped WHERE challenge_ids.assigned_at <= challenge_skipped.at AND challenge_skipped.at <= challenge_closed.at) AS skipped
FROM challenge_ids
JOIN challenge_names ON challenge_ids.i = challenge_names.i
JOIN challenge_closed ON challenge_ids.ch_id = challenge_closed.ch_id;

$_$;


ALTER FUNCTION public.ctf_stats(uuid) OWNER TO blinker_admin;

--
-- Name: events_log_before_create(); Type: FUNCTION; Schema: public; Owner: blinker_admin
--

CREATE FUNCTION events_log_before_create() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO public
    AS $$
BEGIN
NEW.happened_at := current_timestamp;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.events_log_before_create() OWNER TO blinker_admin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ctf_challenges; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE ctf_challenges (
    id character varying(32) NOT NULL,
    ctf uuid NOT NULL,
    flag text NOT NULL,
    handout text,
    package text,
    message text NOT NULL,
    state ctf_challenge_state DEFAULT 'prepared'::ctf_challenge_state NOT NULL,
    deployment_state deployment_state DEFAULT 'none'::deployment_state NOT NULL,
    deployed_to text,
    generated_at timestamp without time zone NOT NULL,
    deployed_at timestamp without time zone,
    deadline timestamp without time zone,
    CONSTRAINT ctf_challenges_check CHECK ((((deployed_to IS NULL) OR ((deployment_state <> ALL (ARRAY['none'::deployment_state, 'initiated'::deployment_state, 'deploying'::deployment_state])) AND (deployed_at IS NOT NULL) AND (deadline IS NOT NULL)))) AND ((deployed_at IS NULL) OR (deployed_to IS NOT NULL)) AND ((deadline IS NULL) OR (deployed_to IS NOT NULL)))
);


ALTER TABLE ctf_challenges OWNER TO blinker_admin;

--
-- Name: ctfs; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE ctfs (
    uuid uuid NOT NULL,
    current_challenge character varying(32),
    challenge_requested boolean DEFAULT false NOT NULL,
    challenge_pending text,
    skip_requested boolean DEFAULT false NOT NULL,
    flag_submission text,
    created_at timestamp without time zone NOT NULL,
    ended_at timestamp without time zone,
    CONSTRAINT ctfs_check CHECK ((((flag_submission IS NULL) OR ((current_challenge IS NOT NULL) AND (NOT skip_requested))) AND ((NOT challenge_requested) OR (current_challenge IS NULL)) AND ((NOT skip_requested) OR (current_challenge IS NOT NULL))))
);


ALTER TABLE ctfs OWNER TO blinker_admin;

--
-- Name: events_log; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE events_log (
    id integer NOT NULL,
    experiment uuid,
    happened_at timestamp without time zone NOT NULL,
    event event_type NOT NULL,
    message text,
    info jsonb
);


ALTER TABLE events_log OWNER TO blinker_admin;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE tokens (
    uuid uuid NOT NULL,
    experiment_kind experiment_kind NOT NULL
);


ALTER TABLE tokens OWNER TO blinker_admin;

--
-- Name: ctf_events; Type: VIEW; Schema: public; Owner: blinker_admin
--

-- TODO consider setting security_barrier = true

CREATE VIEW ctf_events AS
 SELECT events_log.id,
    events_log.event,
    events_log.message,
    events_log.experiment AS uuid,
    (events_log.info ->> 'challenge'::text) AS challenge
   FROM ((events_log
     JOIN tokens ON ((events_log.experiment = tokens.uuid)))
     JOIN ctfs ON ((events_log.experiment = ctfs.uuid)))
  WHERE (tokens.experiment_kind = 'ctf'::experiment_kind);


ALTER TABLE ctf_events OWNER TO blinker_admin;

--
-- Name: ctf_jobs; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE ctf_jobs (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    type ctf_job_type NOT NULL,
    details text,
    result text,
    worker text,
    status ctf_job_status NOT NULL,
    added_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    not_before timestamp without time zone,
    CONSTRAINT ctf_jobs_check CHECK (((status = 'waiting') AND (result IS NULL) AND (worker IS NULL) AND (started_at IS NULL) AND (finished_at IS NULL)) OR
    ((status = 'inprogress') AND (result IS NULL) AND (worker IS NOT NULL) AND (started_at IS NOT NULL) and (finished_at IS NULL)) OR
    ((status IN ('completed','failed')) AND (worker IS NOT NULL) AND (started_at IS NOT NULL) and (finished_at IS NOT NULL)))
);


ALTER TABLE ctf_jobs OWNER TO blinker_admin;

--
-- Name: ctf_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: blinker_admin
--

CREATE SEQUENCE ctf_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ctf_jobs_id_seq OWNER TO blinker_admin;

--
-- Name: ctf_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: blinker_admin
--

ALTER SEQUENCE ctf_jobs_id_seq OWNED BY ctf_jobs.id;


--
-- Name: ctf_jobs_scheduling; Type: VIEW; Schema: public; Owner: blinker_admin
--

CREATE VIEW ctf_jobs_scheduling AS
 SELECT ctf_jobs.id,
    ctf_jobs.uuid,
    ctf_jobs.type,
    ctf_jobs.details,
    ctf_jobs.result,
    ctf_jobs.worker,
    ctf_jobs.status,
    ctf_jobs.added_at,
    ctf_jobs.started_at,
    ctf_jobs.finished_at,
    ctf_jobs.not_before,
    COALESCE(ctf_jobs.not_before, ctf_jobs.added_at) AS schedule_at
   FROM ctf_jobs
  WHERE ((ctf_jobs.status = ANY (ARRAY['waiting'::ctf_job_status, 'inprogress'::ctf_job_status])) AND ((ctf_jobs.not_before IS NULL) OR (ctf_jobs.not_before < now())));


ALTER TABLE ctf_jobs_scheduling OWNER TO blinker_admin;

--
-- Name: ctf_solved; Type: VIEW; Schema: public; Owner: blinker_admin
--

CREATE VIEW ctf_solved AS
 WITH generated AS (
         SELECT ctf_jobs.uuid,
            ctf_jobs.details,
            row_number() OVER (PARTITION BY ctf_jobs.uuid ORDER BY ctf_jobs.id) AS i
           FROM ctf_jobs
          WHERE (ctf_jobs.type = 'generate_challenge'::ctf_job_type)
        ), finished AS (
         SELECT events_log.experiment,
            events_log.event,
            row_number() OVER (PARTITION BY events_log.experiment ORDER BY events_log.id) AS i
           FROM events_log
          WHERE (events_log.event = ANY (ARRAY['flag_accepted'::event_type, 'skip_requested'::event_type]))
        )
 SELECT generated.details AS ch_name,
    count(generated.uuid) AS count
   FROM (generated
     LEFT JOIN finished ON (((generated.uuid = finished.experiment) AND (generated.i = finished.i))))
  WHERE (finished.event = 'flag_accepted'::event_type)
  GROUP BY generated.details;


ALTER TABLE ctf_solved OWNER TO blinker_admin;

--
-- Name: events_log_id_seq; Type: SEQUENCE; Schema: public; Owner: blinker_admin
--

CREATE SEQUENCE events_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE events_log_id_seq OWNER TO blinker_admin;

--
-- Name: events_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: blinker_admin
--

ALTER SEQUENCE events_log_id_seq OWNED BY events_log.id;


--
-- Name: survey_responses; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE survey_responses (
    uuid uuid NOT NULL,
    response jsonb NOT NULL
);


ALTER TABLE survey_responses OWNER TO blinker_admin;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctf_jobs ALTER COLUMN id SET DEFAULT nextval('ctf_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY events_log ALTER COLUMN id SET DEFAULT nextval('events_log_id_seq'::regclass);


--
-- Name: ctf_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctf_challenges
    ADD CONSTRAINT ctf_challenges_pkey PRIMARY KEY (id);


--
-- Name: ctf_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctf_jobs
    ADD CONSTRAINT ctf_jobs_pkey PRIMARY KEY (id);


--
-- Name: ctfs_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctfs
    ADD CONSTRAINT ctfs_pkey PRIMARY KEY (uuid);


--
-- Name: events_log_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY events_log
    ADD CONSTRAINT events_log_pkey PRIMARY KEY (id);


--
-- Name: survey_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY survey_responses
    ADD CONSTRAINT survey_responses_pkey PRIMARY KEY (uuid);


--
-- Name: tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (uuid);


--
-- Name: uuid_unique; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT uuid_unique UNIQUE (uuid);


--
-- Name: ctf_after_create; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_after_create AFTER INSERT ON ctfs FOR EACH ROW EXECUTE PROCEDURE ctf_after_create();


--
-- Name: ctf_after_update; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_after_update AFTER UPDATE ON ctfs FOR EACH ROW EXECUTE PROCEDURE ctf_after_update();


--
-- Name: ctf_before_create; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_before_create BEFORE INSERT ON ctfs FOR EACH ROW EXECUTE PROCEDURE ctf_before_create();


--
-- Name: ctf_before_update; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_before_update BEFORE UPDATE ON ctfs FOR EACH ROW EXECUTE PROCEDURE ctf_before_update();


--
-- Name: ctf_challenge_after_create; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_challenge_after_create AFTER INSERT ON ctf_challenges FOR EACH ROW EXECUTE PROCEDURE ctf_challenge_after_create();


--
-- Name: ctf_challenge_after_update; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_challenge_after_update AFTER UPDATE ON ctf_challenges FOR EACH ROW EXECUTE PROCEDURE ctf_challenge_after_update();


--
-- Name: ctf_challenge_before_create; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_challenge_before_create BEFORE INSERT ON ctf_challenges FOR EACH ROW EXECUTE PROCEDURE ctf_challenge_before_create();


--
-- Name: ctf_challenge_before_update; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_challenge_before_update BEFORE UPDATE ON ctf_challenges FOR EACH ROW EXECUTE PROCEDURE ctf_challenge_before_update();


--
-- Name: ctf_job_after_update; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_job_after_update AFTER UPDATE ON ctf_jobs FOR EACH ROW EXECUTE PROCEDURE ctf_job_after_update();


--
-- Name: ctf_job_before_create; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_job_before_create BEFORE INSERT ON ctf_jobs FOR EACH ROW EXECUTE PROCEDURE ctf_job_before_create();


--
-- Name: ctf_job_before_update; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_job_before_update BEFORE UPDATE ON ctf_jobs FOR EACH ROW EXECUTE PROCEDURE ctf_job_before_update();


--
-- Name: ctf_jobs_notify; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER ctf_jobs_notify AFTER INSERT ON ctf_jobs FOR EACH ROW EXECUTE PROCEDURE ctf_jobs_notify();


--
-- Name: events_log_before_create; Type: TRIGGER; Schema: public; Owner: blinker_admin
--

CREATE TRIGGER events_log_before_create BEFORE INSERT ON events_log FOR EACH ROW EXECUTE PROCEDURE events_log_before_create();


--
-- Name: ctf_challenges_ctf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctf_challenges
    ADD CONSTRAINT ctf_challenges_ctf_fkey FOREIGN KEY (ctf) REFERENCES ctfs(uuid) ON DELETE CASCADE;


--
-- Name: ctf_jobs_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctf_jobs
    ADD CONSTRAINT ctf_jobs_uuid_fkey FOREIGN KEY (uuid) REFERENCES tokens(uuid) ON DELETE CASCADE;


--
-- Name: ctfs_current_challenge_fkey; Type: FK CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctfs
    ADD CONSTRAINT ctfs_current_challenge_fkey FOREIGN KEY (current_challenge) REFERENCES ctf_challenges(id);


--
-- Name: ctfs_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY ctfs
    ADD CONSTRAINT ctfs_uuid_fkey FOREIGN KEY (uuid) REFERENCES tokens(uuid) ON DELETE CASCADE;


--
-- Name: events_log_experiment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY events_log
    ADD CONSTRAINT events_log_experiment_fkey FOREIGN KEY (experiment) REFERENCES tokens(uuid) ON DELETE CASCADE;


--
-- Name: survey_responses_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY survey_responses
    ADD CONSTRAINT survey_responses_uuid_fkey FOREIGN KEY (uuid) REFERENCES tokens(uuid) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO PUBLIC;

-- TODO consider setting permissions on a column-by-column basis

--
-- Name: ctf_challenges; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE ctf_challenges FROM PUBLIC;
REVOKE ALL ON TABLE ctf_challenges FROM blinker_admin;
GRANT ALL ON TABLE ctf_challenges TO blinker_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE ctf_challenges TO blinker_ctf;


--
-- Name: ctfs; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE ctfs FROM PUBLIC;
REVOKE ALL ON TABLE ctfs FROM blinker_admin;
GRANT ALL ON TABLE ctfs TO blinker_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE ctfs TO blinker_web;
GRANT SELECT,UPDATE ON TABLE ctfs TO blinker_ctf;


--
-- Name: events_log; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE events_log FROM PUBLIC;
REVOKE ALL ON TABLE events_log FROM blinker_admin;
GRANT ALL ON TABLE events_log TO blinker_admin;
GRANT SELECT,INSERT ON TABLE events_log TO blinker_web;
GRANT SELECT,INSERT ON TABLE events_log TO blinker_ctf;


--
-- Name: tokens; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE tokens FROM PUBLIC;
REVOKE ALL ON TABLE tokens FROM blinker_admin;
GRANT ALL ON TABLE tokens TO blinker_admin;
GRANT SELECT,INSERT ON TABLE tokens TO blinker_web;


--
-- Name: ctf_events; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE ctf_events FROM PUBLIC;
REVOKE ALL ON TABLE ctf_events FROM blinker_admin;
GRANT ALL ON TABLE ctf_events TO blinker_admin;
GRANT SELECT ON TABLE ctf_events TO blinker_web;


--
-- Name: ctf_jobs; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE ctf_jobs FROM PUBLIC;
REVOKE ALL ON TABLE ctf_jobs FROM blinker_admin;
GRANT ALL ON TABLE ctf_jobs TO blinker_admin;
GRANT INSERT ON TABLE ctf_jobs TO blinker_web;
GRANT SELECT,INSERT,UPDATE ON TABLE ctf_jobs TO blinker_ctf;
GRANT SELECT ON TABLE ctf_jobs TO blinker_monitoring;


--
-- Name: ctf_jobs_id_seq; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON SEQUENCE ctf_jobs_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE ctf_jobs_id_seq FROM blinker_admin;
GRANT ALL ON SEQUENCE ctf_jobs_id_seq TO blinker_admin;
GRANT SELECT,USAGE ON SEQUENCE ctf_jobs_id_seq TO blinker_web;
GRANT SELECT,USAGE ON SEQUENCE ctf_jobs_id_seq TO blinker_ctf;


--
-- Name: ctf_jobs_scheduling; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE ctf_jobs_scheduling FROM PUBLIC;
REVOKE ALL ON TABLE ctf_jobs_scheduling FROM blinker_admin;
GRANT ALL ON TABLE ctf_jobs_scheduling TO blinker_admin;
GRANT SELECT ON TABLE ctf_jobs_scheduling TO blinker_web;
GRANT SELECT,UPDATE ON TABLE ctf_jobs_scheduling TO blinker_ctf;


--
-- Name: ctf_solved; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE ctf_solved FROM PUBLIC;
REVOKE ALL ON TABLE ctf_solved FROM blinker_admin;
GRANT ALL ON TABLE ctf_solved TO blinker_admin;
GRANT SELECT ON TABLE ctf_solved TO blinker_ctf;


--
-- Name: events_log_id_seq; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON SEQUENCE events_log_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE events_log_id_seq FROM blinker_admin;
GRANT ALL ON SEQUENCE events_log_id_seq TO blinker_admin;
GRANT SELECT,USAGE ON SEQUENCE events_log_id_seq TO blinker_web;
GRANT SELECT,USAGE ON SEQUENCE events_log_id_seq TO blinker_ctf;


--
-- Name: survey_responses; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE survey_responses FROM PUBLIC;
REVOKE ALL ON TABLE survey_responses FROM blinker_admin;
GRANT ALL ON TABLE survey_responses TO blinker_admin;
GRANT SELECT,INSERT ON TABLE survey_responses TO blinker_web;


--
-- PostgreSQL database dump complete
--

\connect priv

SET default_transaction_read_only = off;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: experiment_kind; Type: TYPE; Schema: public; Owner: blinker_admin
--

CREATE TYPE experiment_kind AS ENUM (
    'survey',
    'ctf'
);


ALTER TYPE experiment_kind OWNER TO blinker_admin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: blinker_admin
--

CREATE TABLE tokens (
    uuid uuid NOT NULL,
    email character varying(100) NOT NULL,
    experiment_kind experiment_kind NOT NULL
);


ALTER TABLE tokens OWNER TO blinker_admin;

--
-- Name: email_experiment_kind_unique; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT email_experiment_kind_unique UNIQUE (email, experiment_kind);


--
-- Name: tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (uuid);


--
-- Name: uuid_unique; Type: CONSTRAINT; Schema: public; Owner: blinker_admin
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT uuid_unique UNIQUE (uuid);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: tokens; Type: ACL; Schema: public; Owner: blinker_admin
--

REVOKE ALL ON TABLE tokens FROM PUBLIC;
REVOKE ALL ON TABLE tokens FROM blinker_admin;
GRANT ALL ON TABLE tokens TO blinker_admin;
GRANT INSERT ON TABLE tokens TO blinker_web;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

