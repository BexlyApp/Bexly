


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


CREATE SCHEMA IF NOT EXISTS "bexly";


ALTER SCHEMA "bexly" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";








ALTER SCHEMA "public" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "stripe";


ALTER SCHEMA "stripe" OWNER TO "postgres";


COMMENT ON SCHEMA "stripe" IS 'stripe-sync v1.0.18 installed';



CREATE SCHEMA IF NOT EXISTS "web3";


ALTER SCHEMA "web3" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgmq";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "stripe"."invoice_status" AS ENUM (
    'draft',
    'open',
    'paid',
    'uncollectible',
    'void',
    'deleted'
);


ALTER TYPE "stripe"."invoice_status" OWNER TO "postgres";


CREATE TYPE "stripe"."pricing_tiers" AS ENUM (
    'graduated',
    'volume'
);


ALTER TYPE "stripe"."pricing_tiers" OWNER TO "postgres";


CREATE TYPE "stripe"."pricing_type" AS ENUM (
    'one_time',
    'recurring'
);


ALTER TYPE "stripe"."pricing_type" OWNER TO "postgres";


CREATE TYPE "stripe"."subscription_schedule_status" AS ENUM (
    'not_started',
    'active',
    'completed',
    'released',
    'canceled'
);


ALTER TYPE "stripe"."subscription_schedule_status" OWNER TO "postgres";


CREATE TYPE "stripe"."subscription_status" AS ENUM (
    'trialing',
    'active',
    'canceled',
    'incomplete',
    'incomplete_expired',
    'past_due',
    'unpaid',
    'paused'
);


ALTER TYPE "stripe"."subscription_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new._updated_at = now();
  return NEW;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at_metadata"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return NEW;
end;
$$;


ALTER FUNCTION "public"."set_updated_at_metadata"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "bexly"."budget_alerts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "budget_id" "uuid" NOT NULL,
    "threshold_percentage" integer NOT NULL,
    "is_triggered" boolean DEFAULT false NOT NULL,
    "triggered_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."budget_alerts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."budgets" (
    "cloud_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "amount" numeric(20,2) NOT NULL,
    "period" "text" NOT NULL,
    "start_date" "date" NOT NULL,
    "end_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "budgets_period_check" CHECK (("period" = ANY (ARRAY['daily'::"text", 'weekly'::"text", 'monthly'::"text", 'yearly'::"text"])))
);


ALTER TABLE "bexly"."budgets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."categories" (
    "cloud_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "icon" "text",
    "icon_background" "text",
    "icon_type" "text",
    "parent_id" "uuid",
    "description" "text",
    "localized_titles" "text",
    "is_system_default" boolean DEFAULT false NOT NULL,
    "category_type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "categories_category_type_check" CHECK (("category_type" = ANY (ARRAY['income'::"text", 'expense'::"text"])))
);


ALTER TABLE "bexly"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."chat_messages" (
    "message_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "is_from_user" boolean NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    "error" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."chat_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."checklist_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "is_completed" boolean DEFAULT false NOT NULL,
    "due_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."checklist_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."family_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."family_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."family_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "family_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"])))
);


ALTER TABLE "bexly"."family_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "type" "text" NOT NULL,
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."recurring_transactions" (
    "cloud_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "transaction_type" "text" NOT NULL,
    "amount" numeric(20,2) NOT NULL,
    "title" "text" NOT NULL,
    "notes" "text",
    "frequency" "text" NOT NULL,
    "start_date" "date" NOT NULL,
    "end_date" "date",
    "last_executed" timestamp with time zone,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recurring_transactions_frequency_check" CHECK (("frequency" = ANY (ARRAY['daily'::"text", 'weekly'::"text", 'monthly'::"text", 'yearly'::"text"]))),
    CONSTRAINT "recurring_transactions_transaction_type_check" CHECK (("transaction_type" = ANY (ARRAY['income'::"text", 'expense'::"text"])))
);


ALTER TABLE "bexly"."recurring_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."savings_goals" (
    "cloud_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "wallet_id" "uuid",
    "name" "text" NOT NULL,
    "target_amount" numeric(20,2) NOT NULL,
    "current_amount" numeric(20,2) DEFAULT 0 NOT NULL,
    "deadline" "date",
    "is_pinned" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_current_amount" CHECK (("current_amount" >= (0)::numeric)),
    CONSTRAINT "valid_target_amount" CHECK (("target_amount" > (0)::numeric))
);


ALTER TABLE "bexly"."savings_goals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."shared_wallets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "group_id" "uuid" NOT NULL,
    "shared_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."shared_wallets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."transactions" (
    "cloud_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "transaction_type" "text" NOT NULL,
    "amount" numeric(20,2) NOT NULL,
    "currency" character varying(3) NOT NULL,
    "transaction_date" timestamp with time zone NOT NULL,
    "title" "text" NOT NULL,
    "notes" "text",
    "parsed_from_email" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "transactions_transaction_type_check" CHECK (("transaction_type" = ANY (ARRAY['income'::"text", 'expense'::"text", 'transfer'::"text"])))
);


ALTER TABLE "bexly"."transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."user_settings" (
    "user_id" "uuid" NOT NULL,
    "default_currency" character varying(3) DEFAULT 'VND'::character varying NOT NULL,
    "theme" "text" DEFAULT 'system'::"text" NOT NULL,
    "language" "text" DEFAULT 'vi'::"text" NOT NULL,
    "notifications_enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "bexly"."user_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "bexly"."wallets" (
    "cloud_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "currency" character varying(3) DEFAULT 'VND'::character varying NOT NULL,
    "balance" numeric(20,2) DEFAULT 0 NOT NULL,
    "icon" "text",
    "color" "text",
    "wallet_type" "text",
    "billing_date" integer,
    "interest_rate" numeric(5,2),
    "is_shared" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "credit_limit" numeric(20,2)
);


ALTER TABLE "bexly"."wallets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."_prisma_migrations" (
    "id" character varying(36) NOT NULL,
    "checksum" character varying(64) NOT NULL,
    "finished_at" timestamp with time zone,
    "migration_name" character varying(255) NOT NULL,
    "logs" "text",
    "rolled_back_at" timestamp with time zone,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "applied_steps_count" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."_prisma_migrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."activities" (
    "id" "text" NOT NULL,
    "actor_id" "text" NOT NULL,
    "uri" "text" NOT NULL,
    "type" character varying(50) NOT NULL,
    "object_uri" "text",
    "target_uri" "text",
    "raw_data" "jsonb" NOT NULL,
    "delivered" boolean DEFAULT false NOT NULL,
    "delivered_at" timestamp with time zone,
    "delivery_error" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."activities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "text" NOT NULL,
    "table_name" character varying(50) NOT NULL,
    "record_id" character varying(128) NOT NULL,
    "action" character varying(20) NOT NULL,
    "old_data" "jsonb" NOT NULL,
    "performed_by" "uuid",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."auth_providers" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "provider" "text" NOT NULL,
    "provider_id" "text" NOT NULL,
    "provider_data" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "public"."auth_providers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bank_transactions" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "stripe_transaction_id" character varying(255) NOT NULL,
    "stripe_account_id" character varying(255) NOT NULL,
    "amount" integer NOT NULL,
    "currency" character varying(3) NOT NULL,
    "description" "text",
    "status" character varying(50),
    "category" character varying(100),
    "subcategory" character varying(100),
    "transacted_at" timestamp with time zone NOT NULL,
    "posted_at" timestamp with time zone,
    "synced_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "raw_data" "jsonb"
);


ALTER TABLE "public"."bank_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."delivery_queue" (
    "id" "text" NOT NULL,
    "activity_uri" "text" NOT NULL,
    "target_inbox" "text" NOT NULL,
    "attempts" integer DEFAULT 0 NOT NULL,
    "last_attempt_at" timestamp with time zone,
    "next_retry_at" timestamp with time zone,
    "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    "error" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."delivery_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."email_codes" (
    "id" "text" NOT NULL,
    "email" "text" NOT NULL,
    "code" integer NOT NULL,
    "steam_id" "text",
    "key" "text",
    "tag" "text",
    "count" integer DEFAULT 0 NOT NULL,
    "expires_at" timestamp(3) without time zone NOT NULL,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "public"."email_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fed_profiles" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "preferred_username" character varying(50) NOT NULL,
    "name" character varying(100),
    "summary" "text",
    "icon" "text",
    "image" "text",
    "actor_uri" "text" NOT NULL,
    "inbox_uri" "text" NOT NULL,
    "outbox_uri" "text" NOT NULL,
    "followers_uri" "text" NOT NULL,
    "following_uri" "text" NOT NULL,
    "public_key" "text" NOT NULL,
    "private_key" "text" NOT NULL,
    "gamer_tag" character varying(50),
    "platform" "text"[] DEFAULT ARRAY[]::"text"[],
    "games" "jsonb" DEFAULT '[]'::"jsonb",
    "social_links" "jsonb" DEFAULT '{}'::"jsonb",
    "gaming_accounts" "jsonb" DEFAULT '{}'::"jsonb",
    "custom_links" "jsonb" DEFAULT '[]'::"jsonb",
    "profile_theme" character varying(50),
    "accent_color" character varying(20),
    "followers_count" integer DEFAULT 0 NOT NULL,
    "following_count" integer DEFAULT 0 NOT NULL,
    "posts_count" integer DEFAULT 0 NOT NULL,
    "is_bot" boolean DEFAULT false NOT NULL,
    "is_local" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."fed_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."linked_bank_accounts" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "stripe_account_id" character varying(255) NOT NULL,
    "stripe_customer_id" character varying(255),
    "institution_name" character varying(255),
    "institution_icon" character varying(512),
    "display_name" character varying(255),
    "last4" character varying(4),
    "category" character varying(50),
    "subcategory" character varying(50),
    "status" character varying(50) DEFAULT 'active'::character varying NOT NULL,
    "balance_amount" integer,
    "balance_currency" character varying(3),
    "balance_as_of" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."linked_bank_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."nonces" (
    "id" "text" NOT NULL,
    "address" "text" NOT NULL,
    "nonce" integer NOT NULL,
    "tag" "text",
    "count" integer DEFAULT 0 NOT NULL,
    "expires_at" timestamp(3) without time zone NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "public"."nonces" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."org_invites" (
    "id" "text" NOT NULL,
    "org_id" "text" NOT NULL,
    "email" character varying(255) NOT NULL,
    "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
    "token" character varying(64) NOT NULL,
    "invited_by" "uuid" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."org_invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."org_members" (
    "id" "text" NOT NULL,
    "org_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
    "joined_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."org_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "text" NOT NULL,
    "slug" character varying(50) NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" "text",
    "avatar_url" "text",
    "owner_id" "uuid" NOT NULL,
    "billing_email" character varying(255),
    "max_members" integer DEFAULT 10 NOT NULL,
    "settings" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "is_active" boolean DEFAULT true NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_transactions" (
    "id" "text" NOT NULL,
    "stripe_id" "text",
    "object" "text",
    "amount_subtotal" integer DEFAULT 0 NOT NULL,
    "amount_total" integer DEFAULT 0 NOT NULL,
    "currency" "text",
    "status" "text",
    "payment_status" "text",
    "payment_intent" "text",
    "customer" "text",
    "customer_email" "text",
    "customer_details" "jsonb" DEFAULT '{}'::"jsonb",
    "client_reference_id" "text",
    "cancel_url" "text",
    "success_url" "text",
    "url" "text",
    "mode" "text",
    "livemode" boolean DEFAULT false NOT NULL,
    "locale" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "automatic_tax" "jsonb" DEFAULT '{}'::"jsonb",
    "custom_fields" "jsonb" DEFAULT '[]'::"jsonb",
    "custom_text" "jsonb" DEFAULT '{}'::"jsonb",
    "invoice_creation" "jsonb" DEFAULT '{}'::"jsonb",
    "payment_method_types" "text"[] DEFAULT ARRAY[]::"text"[],
    "payment_method_options" "jsonb" DEFAULT '{}'::"jsonb",
    "total_details" "jsonb" DEFAULT '{}'::"jsonb",
    "subscription" "text",
    "invoice" "text",
    "stripe_created" integer,
    "expires_at" integer,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "public"."payment_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."playfab_accounts" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "master_id" "text",
    "player_id" "text",
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL,
    "title_id" "text" DEFAULT 'FA0D0'::"text" NOT NULL,
    "publisher_id" "text"
);


ALTER TABLE "public"."playfab_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_media" (
    "id" "text" NOT NULL,
    "post_id" "text" NOT NULL,
    "type" character varying(20) NOT NULL,
    "url" "text" NOT NULL,
    "preview_url" "text",
    "remote_url" "text",
    "description" "text",
    "blurhash" "text",
    "width" integer,
    "height" integer,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."post_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" "text" NOT NULL,
    "actor_id" "text" NOT NULL,
    "uri" "text" NOT NULL,
    "activity_uri" "text",
    "content" "text" NOT NULL,
    "content_warning" "text",
    "language" character varying(10) DEFAULT 'en'::character varying,
    "in_reply_to_uri" "text",
    "in_reply_to_id" "text",
    "conversation_uri" "text",
    "visibility" character varying(20) DEFAULT 'public'::character varying NOT NULL,
    "game_id" "text",
    "game_name" "text",
    "post_type" character varying(20) DEFAULT 'note'::character varying NOT NULL,
    "likes_count" integer DEFAULT 0 NOT NULL,
    "replies_count" integer DEFAULT 0 NOT NULL,
    "reposts_count" integer DEFAULT 0 NOT NULL,
    "is_local" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "text" NOT NULL,
    "product_id" "text" NOT NULL,
    "item_id" "text",
    "item_name" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "user_id" "uuid" NOT NULL,
    "dos_id" "text",
    "email" "text",
    "display_name" "text",
    "first_name" "text",
    "last_name" "text",
    "username" "text",
    "avatar_url" "text",
    "cover_url" "text",
    "about" "text",
    "phone" "text",
    "country" "text",
    "language" "text" DEFAULT 'en'::"text",
    "birthday" "text",
    "playfab_id" "text",
    "openfort_id" "text",
    "openfort_player_id" "text",
    "referrer_user_id" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "settings" "jsonb" DEFAULT '{}'::"jsonb",
    "firebase_uid" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL,
    "password" "text",
    "password_type" "text" DEFAULT 'md5'::"text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_members" (
    "id" "text" NOT NULL,
    "project_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
    "joined_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."project_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "text" NOT NULL,
    "org_id" "text" NOT NULL,
    "slug" character varying(50) NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" "text",
    "avatar_url" "text",
    "settings" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."remote_actors" (
    "id" "text" NOT NULL,
    "actor_uri" "text" NOT NULL,
    "preferred_username" "text" NOT NULL,
    "domain" "text" NOT NULL,
    "name" "text",
    "summary" "text",
    "icon" "text",
    "image" "text",
    "inbox_uri" "text" NOT NULL,
    "outbox_uri" "text",
    "followers_uri" "text",
    "following_uri" "text",
    "shared_inbox_uri" "text",
    "public_key" "text" NOT NULL,
    "followers_count" integer DEFAULT 0 NOT NULL,
    "following_count" integer DEFAULT 0 NOT NULL,
    "last_fetched_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."remote_actors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."session_keys" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "session_id" "text",
    "session_key" "text" NOT NULL,
    "session_address" "text",
    "session_hash" "text",
    "owner_address" "text",
    "player_id" "text",
    "playfab_id" "text",
    "entity_id" "text",
    "permissions" "jsonb" DEFAULT '[]'::"jsonb",
    "is_active" boolean DEFAULT true NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "expires_at" timestamp(3) without time zone NOT NULL,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."session_keys" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."social_follows" (
    "id" "text" NOT NULL,
    "follower_id" "text" NOT NULL,
    "followee_id" "text" NOT NULL,
    "activity_uri" "text",
    "status" character varying(20) DEFAULT 'accepted'::character varying NOT NULL,
    "remote_actor_uri" "text",
    "is_remote" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."social_follows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."social_likes" (
    "id" "text" NOT NULL,
    "actor_id" "text" NOT NULL,
    "post_id" "text" NOT NULL,
    "activity_uri" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE "public"."social_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stripe_customers" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "stripe_customer_id" character varying(255) NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone NOT NULL
);


ALTER TABLE "public"."stripe_customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."_managed_webhooks" (
    "id" "text" NOT NULL,
    "object" "text",
    "url" "text" NOT NULL,
    "enabled_events" "jsonb" NOT NULL,
    "description" "text",
    "enabled" boolean,
    "livemode" boolean,
    "metadata" "jsonb",
    "secret" "text" NOT NULL,
    "status" "text",
    "api_version" "text",
    "created" integer,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "last_synced_at" timestamp with time zone,
    "account_id" "text" NOT NULL
);


ALTER TABLE "stripe"."_managed_webhooks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."_migrations" (
    "id" integer NOT NULL,
    "name" character varying(100) NOT NULL,
    "hash" character varying(40) NOT NULL,
    "executed_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "stripe"."_migrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."_sync_obj_runs" (
    "_account_id" "text" NOT NULL,
    "run_started_at" timestamp with time zone NOT NULL,
    "object" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "processed_count" integer DEFAULT 0,
    "cursor" "text",
    "error_message" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "_sync_obj_run_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'running'::"text", 'complete'::"text", 'error'::"text"])))
);


ALTER TABLE "stripe"."_sync_obj_runs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."_sync_runs" (
    "_account_id" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "max_concurrent" integer DEFAULT 3 NOT NULL,
    "error_message" "text",
    "triggered_by" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "closed_at" timestamp with time zone
);


ALTER TABLE "stripe"."_sync_runs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."accounts" (
    "_raw_data" "jsonb" NOT NULL,
    "first_synced_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "_last_synced_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "_updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "business_name" "text" GENERATED ALWAYS AS ((("_raw_data" -> 'business_profile'::"text") ->> 'name'::"text")) STORED,
    "email" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'email'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "charges_enabled" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'charges_enabled'::"text"))::boolean) STORED,
    "payouts_enabled" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'payouts_enabled'::"text"))::boolean) STORED,
    "details_submitted" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'details_submitted'::"text"))::boolean) STORED,
    "country" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'country'::"text")) STORED,
    "default_currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_currency'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "api_key_hashes" "text"[] DEFAULT '{}'::"text"[],
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."active_entitlements" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "feature" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'feature'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "lookup_key" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'lookup_key'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."active_entitlements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."charges" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "paid" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'paid'::"text"))::boolean) STORED,
    "order" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'order'::"text")) STORED,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED,
    "review" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'review'::"text")) STORED,
    "source" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'source'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "dispute" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'dispute'::"text")) STORED,
    "invoice" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'invoice'::"text")) STORED,
    "outcome" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'outcome'::"text")) STORED,
    "refunds" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'refunds'::"text")) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "captured" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'captured'::"text"))::boolean) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "refunded" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'refunded'::"text"))::boolean) STORED,
    "shipping" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping'::"text")) STORED,
    "application" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'application'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "destination" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'destination'::"text")) STORED,
    "failure_code" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'failure_code'::"text")) STORED,
    "on_behalf_of" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'on_behalf_of'::"text")) STORED,
    "fraud_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'fraud_details'::"text")) STORED,
    "receipt_email" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'receipt_email'::"text")) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "receipt_number" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'receipt_number'::"text")) STORED,
    "transfer_group" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'transfer_group'::"text")) STORED,
    "amount_refunded" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_refunded'::"text"))::bigint) STORED,
    "application_fee" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'application_fee'::"text")) STORED,
    "failure_message" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'failure_message'::"text")) STORED,
    "source_transfer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'source_transfer'::"text")) STORED,
    "balance_transaction" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'balance_transaction'::"text")) STORED,
    "statement_descriptor" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor'::"text")) STORED,
    "payment_method_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_method_details'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."charges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."checkout_session_line_items" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "price" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'price'::"text")) STORED,
    "quantity" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'quantity'::"text"))::integer) STORED,
    "checkout_session" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'checkout_session'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "amount_discount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_discount'::"text"))::bigint) STORED,
    "amount_subtotal" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_subtotal'::"text"))::bigint) STORED,
    "amount_tax" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_tax'::"text"))::bigint) STORED,
    "amount_total" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_total'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."checkout_session_line_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."checkout_sessions" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "adaptive_pricing" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'adaptive_pricing'::"text")) STORED,
    "after_expiration" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'after_expiration'::"text")) STORED,
    "allow_promotion_codes" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'allow_promotion_codes'::"text"))::boolean) STORED,
    "automatic_tax" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'automatic_tax'::"text")) STORED,
    "billing_address_collection" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'billing_address_collection'::"text")) STORED,
    "cancel_url" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'cancel_url'::"text")) STORED,
    "client_reference_id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'client_reference_id'::"text")) STORED,
    "client_secret" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'client_secret'::"text")) STORED,
    "collected_information" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'collected_information'::"text")) STORED,
    "consent" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'consent'::"text")) STORED,
    "consent_collection" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'consent_collection'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "currency_conversion" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'currency_conversion'::"text")) STORED,
    "custom_fields" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'custom_fields'::"text")) STORED,
    "custom_text" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'custom_text'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "customer_creation" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_creation'::"text")) STORED,
    "customer_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'customer_details'::"text")) STORED,
    "customer_email" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_email'::"text")) STORED,
    "discounts" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'discounts'::"text")) STORED,
    "expires_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'expires_at'::"text"))::integer) STORED,
    "invoice" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'invoice'::"text")) STORED,
    "invoice_creation" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'invoice_creation'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "locale" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'locale'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "mode" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'mode'::"text")) STORED,
    "optional_items" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'optional_items'::"text")) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "payment_link" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_link'::"text")) STORED,
    "payment_method_collection" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_method_collection'::"text")) STORED,
    "payment_method_configuration_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_method_configuration_details'::"text")) STORED,
    "payment_method_options" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_method_options'::"text")) STORED,
    "payment_method_types" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_method_types'::"text")) STORED,
    "payment_status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_status'::"text")) STORED,
    "permissions" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'permissions'::"text")) STORED,
    "phone_number_collection" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'phone_number_collection'::"text")) STORED,
    "presentment_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'presentment_details'::"text")) STORED,
    "recovered_from" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'recovered_from'::"text")) STORED,
    "redirect_on_completion" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'redirect_on_completion'::"text")) STORED,
    "return_url" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'return_url'::"text")) STORED,
    "saved_payment_method_options" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'saved_payment_method_options'::"text")) STORED,
    "setup_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'setup_intent'::"text")) STORED,
    "shipping_address_collection" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping_address_collection'::"text")) STORED,
    "shipping_cost" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping_cost'::"text")) STORED,
    "shipping_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping_details'::"text")) STORED,
    "shipping_options" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping_options'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "submit_type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'submit_type'::"text")) STORED,
    "subscription" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'subscription'::"text")) STORED,
    "success_url" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'success_url'::"text")) STORED,
    "tax_id_collection" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'tax_id_collection'::"text")) STORED,
    "total_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'total_details'::"text")) STORED,
    "ui_mode" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'ui_mode'::"text")) STORED,
    "url" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'url'::"text")) STORED,
    "wallet_options" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'wallet_options'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "amount_subtotal" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_subtotal'::"text"))::bigint) STORED,
    "amount_total" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_total'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."checkout_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."coupons" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'name'::"text")) STORED,
    "valid" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'valid'::"text"))::boolean) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "duration" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'duration'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "redeem_by" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'redeem_by'::"text"))::integer) STORED,
    "amount_off" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_off'::"text"))::bigint) STORED,
    "percent_off" double precision GENERATED ALWAYS AS ((("_raw_data" ->> 'percent_off'::"text"))::double precision) STORED,
    "times_redeemed" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'times_redeemed'::"text"))::bigint) STORED,
    "max_redemptions" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'max_redemptions'::"text"))::bigint) STORED,
    "duration_in_months" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'duration_in_months'::"text"))::bigint) STORED,
    "percent_off_precise" double precision GENERATED ALWAYS AS ((("_raw_data" ->> 'percent_off_precise'::"text"))::double precision) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."coupons" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."credit_notes" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "customer_balance_transaction" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_balance_transaction'::"text")) STORED,
    "discount_amounts" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'discount_amounts'::"text")) STORED,
    "invoice" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'invoice'::"text")) STORED,
    "lines" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'lines'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "memo" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'memo'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "number" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'number'::"text")) STORED,
    "pdf" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'pdf'::"text")) STORED,
    "reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'reason'::"text")) STORED,
    "refund" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'refund'::"text")) STORED,
    "shipping_cost" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping_cost'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "tax_amounts" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'tax_amounts'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "voided_at" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'voided_at'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED,
    "amount_shipping" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_shipping'::"text"))::bigint) STORED,
    "discount_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'discount_amount'::"text"))::bigint) STORED,
    "out_of_band_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'out_of_band_amount'::"text"))::bigint) STORED,
    "subtotal" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'subtotal'::"text"))::bigint) STORED,
    "subtotal_excluding_tax" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'subtotal_excluding_tax'::"text"))::bigint) STORED,
    "total" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'total'::"text"))::bigint) STORED,
    "total_excluding_tax" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'total_excluding_tax'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."credit_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."customers" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "address" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'address'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "email" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'email'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'name'::"text")) STORED,
    "phone" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'phone'::"text")) STORED,
    "shipping" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "default_source" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_source'::"text")) STORED,
    "delinquent" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'delinquent'::"text"))::boolean) STORED,
    "discount" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'discount'::"text")) STORED,
    "invoice_prefix" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'invoice_prefix'::"text")) STORED,
    "invoice_settings" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'invoice_settings'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "next_invoice_sequence" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'next_invoice_sequence'::"text"))::integer) STORED,
    "preferred_locales" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'preferred_locales'::"text")) STORED,
    "tax_exempt" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'tax_exempt'::"text")) STORED,
    "deleted" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'deleted'::"text"))::boolean) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "balance" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'balance'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."disputes" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED,
    "charge" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'charge'::"text")) STORED,
    "reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'reason'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "evidence" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'evidence'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "evidence_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'evidence_details'::"text")) STORED,
    "balance_transactions" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'balance_transactions'::"text")) STORED,
    "is_charge_refundable" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'is_charge_refundable'::"text"))::boolean) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."disputes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."early_fraud_warnings" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "actionable" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'actionable'::"text"))::boolean) STORED,
    "charge" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'charge'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "fraud_type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'fraud_type'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."early_fraud_warnings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."events" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "data" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'data'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "request" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'request'::"text")) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "api_version" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'api_version'::"text")) STORED,
    "pending_webhooks" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'pending_webhooks'::"text"))::bigint) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."exchange_rates_from_usd" (
    "_raw_data" "jsonb" NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_updated_at" timestamp with time zone DEFAULT "now"(),
    "_account_id" "text" NOT NULL,
    "date" "date" NOT NULL,
    "sell_currency" "text" NOT NULL,
    "buy_currency_exchange_rates" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'buy_currency_exchange_rates'::"text"), ''::"text")) STORED
);


ALTER TABLE "stripe"."exchange_rates_from_usd" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."features" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'name'::"text")) STORED,
    "lookup_key" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'lookup_key'::"text")) STORED,
    "active" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'active'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."features" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."invoices" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "auto_advance" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'auto_advance'::"text"))::boolean) STORED,
    "collection_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'collection_method'::"text")) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "hosted_invoice_url" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'hosted_invoice_url'::"text")) STORED,
    "lines" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'lines'::"text")) STORED,
    "period_end" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'period_end'::"text"))::integer) STORED,
    "period_start" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'period_start'::"text"))::integer) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "total" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'total'::"text"))::bigint) STORED,
    "account_country" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'account_country'::"text")) STORED,
    "account_name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'account_name'::"text")) STORED,
    "account_tax_ids" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'account_tax_ids'::"text")) STORED,
    "amount_due" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_due'::"text"))::bigint) STORED,
    "amount_paid" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_paid'::"text"))::bigint) STORED,
    "amount_remaining" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_remaining'::"text"))::bigint) STORED,
    "application_fee_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'application_fee_amount'::"text"))::bigint) STORED,
    "attempt_count" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'attempt_count'::"text"))::integer) STORED,
    "attempted" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'attempted'::"text"))::boolean) STORED,
    "billing_reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'billing_reason'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "custom_fields" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'custom_fields'::"text")) STORED,
    "customer_address" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'customer_address'::"text")) STORED,
    "customer_email" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_email'::"text")) STORED,
    "customer_name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_name'::"text")) STORED,
    "customer_phone" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_phone'::"text")) STORED,
    "customer_shipping" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'customer_shipping'::"text")) STORED,
    "customer_tax_exempt" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer_tax_exempt'::"text")) STORED,
    "customer_tax_ids" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'customer_tax_ids'::"text")) STORED,
    "default_tax_rates" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'default_tax_rates'::"text")) STORED,
    "discount" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'discount'::"text")) STORED,
    "discounts" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'discounts'::"text")) STORED,
    "due_date" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'due_date'::"text"))::integer) STORED,
    "footer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'footer'::"text")) STORED,
    "invoice_pdf" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'invoice_pdf'::"text")) STORED,
    "last_finalization_error" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'last_finalization_error'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "next_payment_attempt" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'next_payment_attempt'::"text"))::integer) STORED,
    "number" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'number'::"text")) STORED,
    "paid" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'paid'::"text"))::boolean) STORED,
    "payment_settings" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_settings'::"text")) STORED,
    "receipt_number" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'receipt_number'::"text")) STORED,
    "statement_descriptor" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor'::"text")) STORED,
    "status_transitions" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'status_transitions'::"text")) STORED,
    "total_discount_amounts" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'total_discount_amounts'::"text")) STORED,
    "total_tax_amounts" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'total_tax_amounts'::"text")) STORED,
    "transfer_data" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'transfer_data'::"text")) STORED,
    "webhooks_delivered_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'webhooks_delivered_at'::"text"))::integer) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "subscription" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'subscription'::"text")) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "default_payment_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_payment_method'::"text")) STORED,
    "default_source" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_source'::"text")) STORED,
    "on_behalf_of" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'on_behalf_of'::"text")) STORED,
    "charge" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'charge'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "ending_balance" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'ending_balance'::"text"))::bigint) STORED,
    "starting_balance" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'starting_balance'::"text"))::bigint) STORED,
    "subtotal" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'subtotal'::"text"))::bigint) STORED,
    "tax" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'tax'::"text"))::bigint) STORED,
    "post_payment_credit_notes_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'post_payment_credit_notes_amount'::"text"))::bigint) STORED,
    "pre_payment_credit_notes_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'pre_payment_credit_notes_amount'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."payment_intents" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "amount_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'amount_details'::"text")) STORED,
    "application" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'application'::"text")) STORED,
    "automatic_payment_methods" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'automatic_payment_methods'::"text")) STORED,
    "canceled_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'canceled_at'::"text"))::integer) STORED,
    "cancellation_reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'cancellation_reason'::"text")) STORED,
    "capture_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'capture_method'::"text")) STORED,
    "client_secret" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'client_secret'::"text")) STORED,
    "confirmation_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'confirmation_method'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "invoice" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'invoice'::"text")) STORED,
    "last_payment_error" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'last_payment_error'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "next_action" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'next_action'::"text")) STORED,
    "on_behalf_of" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'on_behalf_of'::"text")) STORED,
    "payment_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_method'::"text")) STORED,
    "payment_method_options" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_method_options'::"text")) STORED,
    "payment_method_types" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'payment_method_types'::"text")) STORED,
    "processing" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'processing'::"text")) STORED,
    "receipt_email" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'receipt_email'::"text")) STORED,
    "review" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'review'::"text")) STORED,
    "setup_future_usage" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'setup_future_usage'::"text")) STORED,
    "shipping" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'shipping'::"text")) STORED,
    "statement_descriptor" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor'::"text")) STORED,
    "statement_descriptor_suffix" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor_suffix'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "transfer_data" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'transfer_data'::"text")) STORED,
    "transfer_group" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'transfer_group'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED,
    "amount_capturable" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_capturable'::"text"))::bigint) STORED,
    "amount_received" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_received'::"text"))::bigint) STORED,
    "application_fee_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'application_fee_amount'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."payment_intents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."payment_methods" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "billing_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'billing_details'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "card" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'card'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."payment_methods" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."payouts" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "date" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'date'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED,
    "method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'method'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "automatic" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'automatic'::"text"))::boolean) STORED,
    "recipient" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'recipient'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "destination" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'destination'::"text")) STORED,
    "source_type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'source_type'::"text")) STORED,
    "arrival_date" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'arrival_date'::"text")) STORED,
    "bank_account" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'bank_account'::"text")) STORED,
    "failure_code" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'failure_code'::"text")) STORED,
    "transfer_group" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'transfer_group'::"text")) STORED,
    "amount_reversed" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount_reversed'::"text"))::bigint) STORED,
    "failure_message" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'failure_message'::"text")) STORED,
    "source_transaction" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'source_transaction'::"text")) STORED,
    "balance_transaction" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'balance_transaction'::"text")) STORED,
    "statement_descriptor" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor'::"text")) STORED,
    "statement_description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_description'::"text")) STORED,
    "failure_balance_transaction" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'failure_balance_transaction'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."payouts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."plans" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'name'::"text")) STORED,
    "tiers" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'tiers'::"text")) STORED,
    "active" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'active'::"text"))::boolean) STORED,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "product" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'product'::"text")) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "interval" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'interval'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "nickname" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'nickname'::"text")) STORED,
    "tiers_mode" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'tiers_mode'::"text")) STORED,
    "usage_type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'usage_type'::"text")) STORED,
    "billing_scheme" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'billing_scheme'::"text")) STORED,
    "interval_count" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'interval_count'::"text"))::bigint) STORED,
    "aggregate_usage" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'aggregate_usage'::"text")) STORED,
    "transform_usage" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'transform_usage'::"text")) STORED,
    "trial_period_days" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'trial_period_days'::"text"))::bigint) STORED,
    "statement_descriptor" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor'::"text")) STORED,
    "statement_description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_description'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."prices" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "active" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'active'::"text"))::boolean) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "nickname" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'nickname'::"text")) STORED,
    "recurring" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'recurring'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "billing_scheme" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'billing_scheme'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "lookup_key" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'lookup_key'::"text")) STORED,
    "tiers_mode" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'tiers_mode'::"text")) STORED,
    "transform_quantity" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'transform_quantity'::"text")) STORED,
    "unit_amount_decimal" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'unit_amount_decimal'::"text")) STORED,
    "product" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'product'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "unit_amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'unit_amount'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."prices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."products" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "active" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'active'::"text"))::boolean) STORED,
    "default_price" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_price'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "name" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'name'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "images" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'images'::"text")) STORED,
    "marketing_features" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'marketing_features'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "package_dimensions" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'package_dimensions'::"text")) STORED,
    "shippable" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'shippable'::"text"))::boolean) STORED,
    "statement_descriptor" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'statement_descriptor'::"text")) STORED,
    "unit_label" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'unit_label'::"text")) STORED,
    "updated" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'updated'::"text"))::integer) STORED,
    "url" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'url'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."refunds" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "balance_transaction" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'balance_transaction'::"text")) STORED,
    "charge" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'charge'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "currency" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'currency'::"text")) STORED,
    "destination_details" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'destination_details'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'reason'::"text")) STORED,
    "receipt_number" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'receipt_number'::"text")) STORED,
    "source_transfer_reversal" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'source_transfer_reversal'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "transfer_reversal" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'transfer_reversal'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL,
    "amount" bigint GENERATED ALWAYS AS ((("_raw_data" ->> 'amount'::"text"))::bigint) STORED
);


ALTER TABLE "stripe"."refunds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."reviews" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "billing_zip" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'billing_zip'::"text")) STORED,
    "charge" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'charge'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "closed_reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'closed_reason'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "ip_address" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'ip_address'::"text")) STORED,
    "ip_address_location" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'ip_address_location'::"text")) STORED,
    "open" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'open'::"text"))::boolean) STORED,
    "opened_reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'opened_reason'::"text")) STORED,
    "payment_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_intent'::"text")) STORED,
    "reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'reason'::"text")) STORED,
    "session" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'session'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."reviews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."setup_intents" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "description" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'description'::"text")) STORED,
    "payment_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'payment_method'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "usage" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'usage'::"text")) STORED,
    "cancellation_reason" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'cancellation_reason'::"text")) STORED,
    "latest_attempt" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'latest_attempt'::"text")) STORED,
    "mandate" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'mandate'::"text")) STORED,
    "single_use_mandate" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'single_use_mandate'::"text")) STORED,
    "on_behalf_of" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'on_behalf_of'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."setup_intents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."subscription_item_change_events_v2_beta" (
    "_raw_data" "jsonb" NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_updated_at" timestamp with time zone DEFAULT "now"(),
    "_account_id" "text" NOT NULL,
    "event_timestamp" timestamp with time zone NOT NULL,
    "event_type" "text" NOT NULL,
    "subscription_item_id" "text" NOT NULL,
    "currency" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'currency'::"text"), ''::"text")) STORED,
    "mrr_change" bigint GENERATED ALWAYS AS ((NULLIF(("_raw_data" ->> 'mrr_change'::"text"), ''::"text"))::bigint) STORED,
    "quantity_change" bigint GENERATED ALWAYS AS ((NULLIF(("_raw_data" ->> 'quantity_change'::"text"), ''::"text"))::bigint) STORED,
    "subscription_id" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'subscription_id'::"text"), ''::"text")) STORED,
    "customer_id" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'customer_id'::"text"), ''::"text")) STORED,
    "price_id" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'price_id'::"text"), ''::"text")) STORED,
    "product_id" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'product_id'::"text"), ''::"text")) STORED,
    "local_event_timestamp" "text" GENERATED ALWAYS AS (NULLIF(("_raw_data" ->> 'local_event_timestamp'::"text"), ''::"text")) STORED
);


ALTER TABLE "stripe"."subscription_item_change_events_v2_beta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."subscription_items" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "billing_thresholds" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'billing_thresholds'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "deleted" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'deleted'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "quantity" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'quantity'::"text"))::integer) STORED,
    "price" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'price'::"text")) STORED,
    "subscription" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'subscription'::"text")) STORED,
    "tax_rates" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'tax_rates'::"text")) STORED,
    "current_period_end" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'current_period_end'::"text"))::integer) STORED,
    "current_period_start" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'current_period_start'::"text"))::integer) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."subscription_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."subscription_schedules" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "application" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'application'::"text")) STORED,
    "canceled_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'canceled_at'::"text"))::integer) STORED,
    "completed_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'completed_at'::"text"))::integer) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "current_phase" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'current_phase'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "default_settings" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'default_settings'::"text")) STORED,
    "end_behavior" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'end_behavior'::"text")) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "phases" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'phases'::"text")) STORED,
    "released_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'released_at'::"text"))::integer) STORED,
    "released_subscription" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'released_subscription'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "subscription" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'subscription'::"text")) STORED,
    "test_clock" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'test_clock'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."subscription_schedules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."subscriptions" (
    "_updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "cancel_at_period_end" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'cancel_at_period_end'::"text"))::boolean) STORED,
    "current_period_end" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'current_period_end'::"text"))::integer) STORED,
    "current_period_start" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'current_period_start'::"text"))::integer) STORED,
    "default_payment_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_payment_method'::"text")) STORED,
    "items" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'items'::"text")) STORED,
    "metadata" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'metadata'::"text")) STORED,
    "pending_setup_intent" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'pending_setup_intent'::"text")) STORED,
    "pending_update" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'pending_update'::"text")) STORED,
    "status" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'status'::"text")) STORED,
    "application_fee_percent" double precision GENERATED ALWAYS AS ((("_raw_data" ->> 'application_fee_percent'::"text"))::double precision) STORED,
    "billing_cycle_anchor" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'billing_cycle_anchor'::"text"))::integer) STORED,
    "billing_thresholds" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'billing_thresholds'::"text")) STORED,
    "cancel_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'cancel_at'::"text"))::integer) STORED,
    "canceled_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'canceled_at'::"text"))::integer) STORED,
    "collection_method" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'collection_method'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "days_until_due" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'days_until_due'::"text"))::integer) STORED,
    "default_source" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'default_source'::"text")) STORED,
    "default_tax_rates" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'default_tax_rates'::"text")) STORED,
    "discount" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'discount'::"text")) STORED,
    "ended_at" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'ended_at'::"text"))::integer) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "next_pending_invoice_item_invoice" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'next_pending_invoice_item_invoice'::"text"))::integer) STORED,
    "pause_collection" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'pause_collection'::"text")) STORED,
    "pending_invoice_item_interval" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'pending_invoice_item_interval'::"text")) STORED,
    "start_date" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'start_date'::"text"))::integer) STORED,
    "transfer_data" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'transfer_data'::"text")) STORED,
    "trial_end" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'trial_end'::"text")) STORED,
    "trial_start" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'trial_start'::"text")) STORED,
    "schedule" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'schedule'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "latest_invoice" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'latest_invoice'::"text")) STORED,
    "plan" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'plan'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."subscriptions" OWNER TO "postgres";


CREATE OR REPLACE VIEW "stripe"."sync_runs" AS
 SELECT "r"."_account_id" AS "account_id",
    "r"."started_at",
    "r"."closed_at",
    "r"."triggered_by",
    "r"."max_concurrent",
    COALESCE("sum"("o"."processed_count"), (0)::bigint) AS "total_processed",
    "count"("o".*) AS "total_objects",
    "count"(*) FILTER (WHERE ("o"."status" = 'complete'::"text")) AS "complete_count",
    "count"(*) FILTER (WHERE ("o"."status" = 'error'::"text")) AS "error_count",
    "count"(*) FILTER (WHERE ("o"."status" = 'running'::"text")) AS "running_count",
    "count"(*) FILTER (WHERE ("o"."status" = 'pending'::"text")) AS "pending_count",
    "string_agg"("o"."error_message", '; '::"text") FILTER (WHERE ("o"."error_message" IS NOT NULL)) AS "error_message",
        CASE
            WHEN (("r"."closed_at" IS NULL) AND ("count"(*) FILTER (WHERE ("o"."status" = 'running'::"text")) > 0)) THEN 'running'::"text"
            WHEN (("r"."closed_at" IS NULL) AND (("count"("o".*) = 0) OR ("count"("o".*) = "count"(*) FILTER (WHERE ("o"."status" = 'pending'::"text"))))) THEN 'pending'::"text"
            WHEN ("r"."closed_at" IS NULL) THEN 'running'::"text"
            WHEN ("count"(*) FILTER (WHERE ("o"."status" = 'error'::"text")) > 0) THEN 'error'::"text"
            ELSE 'complete'::"text"
        END AS "status"
   FROM ("stripe"."_sync_runs" "r"
     LEFT JOIN "stripe"."_sync_obj_runs" "o" ON ((("o"."_account_id" = "r"."_account_id") AND ("o"."run_started_at" = "r"."started_at"))))
  GROUP BY "r"."_account_id", "r"."started_at", "r"."closed_at", "r"."triggered_by", "r"."max_concurrent";


ALTER VIEW "stripe"."sync_runs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "stripe"."tax_ids" (
    "_last_synced_at" timestamp with time zone,
    "_raw_data" "jsonb",
    "_account_id" "text" NOT NULL,
    "object" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'object'::"text")) STORED,
    "country" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'country'::"text")) STORED,
    "customer" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'customer'::"text")) STORED,
    "type" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'type'::"text")) STORED,
    "value" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'value'::"text")) STORED,
    "created" integer GENERATED ALWAYS AS ((("_raw_data" ->> 'created'::"text"))::integer) STORED,
    "livemode" boolean GENERATED ALWAYS AS ((("_raw_data" ->> 'livemode'::"text"))::boolean) STORED,
    "owner" "jsonb" GENERATED ALWAYS AS (("_raw_data" -> 'owner'::"text")) STORED,
    "id" "text" GENERATED ALWAYS AS (("_raw_data" ->> 'id'::"text")) STORED NOT NULL
);


ALTER TABLE "stripe"."tax_ids" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "web3"."chains" (
    "id" integer NOT NULL,
    "chain_id" integer NOT NULL,
    "name" "text" NOT NULL,
    "symbol" "text" NOT NULL,
    "icon" "text",
    "rpc_url" "text" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "current_block" bigint,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "web3"."chains" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "web3"."chains_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "web3"."chains_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "web3"."chains_id_seq" OWNED BY "web3"."chains"."id";



CREATE TABLE IF NOT EXISTS "web3"."games" (
    "id" "uuid" NOT NULL,
    "key" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "avatar" "text",
    "cover" "text",
    "featured_image" "text",
    "collections" "jsonb" DEFAULT '[]'::"jsonb",
    "owners" "jsonb" DEFAULT '[]'::"jsonb",
    "socials" "jsonb" DEFAULT '{}'::"jsonb",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL,
    "last_updated" timestamp(3) without time zone
);


ALTER TABLE "web3"."games" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "web3"."marketplace_orders" (
    "id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "status" "text" NOT NULL,
    "owner_address" "text" NOT NULL,
    "price_usd" numeric(20,2),
    "payment_amount" numeric(30,0) NOT NULL,
    "payment_token_address" "text",
    "order_hash" "text" NOT NULL,
    "seaport_order" "jsonb" NOT NULL,
    "nft_id" "uuid" NOT NULL,
    "nft_amount" integer DEFAULT 1 NOT NULL,
    "chain_id" integer NOT NULL,
    "current_block" bigint,
    "tx_hash" "text",
    "bundle_id" "uuid",
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL,
    "collection_id" "uuid" NOT NULL
);


ALTER TABLE "web3"."marketplace_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "web3"."nft_collections" (
    "id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "symbol" "text",
    "description" "text",
    "avatar" "text",
    "cover" "text",
    "featured_image" "text",
    "chain_id" integer NOT NULL,
    "contract_address" "text" NOT NULL,
    "creator" "text",
    "is_verified" boolean DEFAULT false NOT NULL,
    "socials" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "web3"."nft_collections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "web3"."nfts" (
    "id" "uuid" NOT NULL,
    "chain_id" integer NOT NULL,
    "contract_address" "text" NOT NULL,
    "token_id" "text" NOT NULL,
    "token_type" "text" DEFAULT 'ERC721'::"text" NOT NULL,
    "name" "text",
    "description" "text",
    "image" "text",
    "origin_image" "text",
    "external_url" "text",
    "animation_url" "text",
    "animation_play_type" "text",
    "token_url" "text",
    "attributes" "jsonb" DEFAULT '[]'::"jsonb",
    "owners" "jsonb" DEFAULT '[]'::"jsonb",
    "market_type" "text" DEFAULT 'NotForSale'::"text" NOT NULL,
    "price" numeric(20,2),
    "payment_address" "text",
    "payment_amount" numeric(30,0),
    "is_burned" boolean DEFAULT false NOT NULL,
    "burned_at" timestamp(3) without time zone,
    "current_block" bigint,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL,
    "collection_id" "uuid" NOT NULL
);


ALTER TABLE "web3"."nfts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "web3"."payment_tokens" (
    "id" "uuid" NOT NULL,
    "chain_id" integer NOT NULL,
    "address" "text" NOT NULL,
    "symbol" "text" NOT NULL,
    "name" "text" NOT NULL,
    "decimals" integer DEFAULT 18 NOT NULL,
    "icon" "text",
    "price_usd" numeric(20,8),
    "last_price_update" timestamp(3) without time zone,
    "enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "web3"."payment_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "web3"."wallet_users" (
    "id" "uuid" NOT NULL,
    "address" "text" NOT NULL,
    "name" "text",
    "username" "text",
    "avatar" "text",
    "created_at" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp(3) without time zone NOT NULL
);


ALTER TABLE "web3"."wallet_users" OWNER TO "postgres";


ALTER TABLE ONLY "web3"."chains" ALTER COLUMN "id" SET DEFAULT "nextval"('"web3"."chains_id_seq"'::"regclass");



ALTER TABLE ONLY "bexly"."budget_alerts"
    ADD CONSTRAINT "budget_alerts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "bexly"."budgets"
    ADD CONSTRAINT "budgets_pkey" PRIMARY KEY ("cloud_id");



ALTER TABLE ONLY "bexly"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("cloud_id");



ALTER TABLE ONLY "bexly"."chat_messages"
    ADD CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("message_id");



ALTER TABLE ONLY "bexly"."checklist_items"
    ADD CONSTRAINT "checklist_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "bexly"."family_groups"
    ADD CONSTRAINT "family_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "bexly"."family_members"
    ADD CONSTRAINT "family_members_group_id_user_id_key" UNIQUE ("group_id", "user_id");



ALTER TABLE ONLY "bexly"."family_members"
    ADD CONSTRAINT "family_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "bexly"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "bexly"."recurring_transactions"
    ADD CONSTRAINT "recurring_transactions_pkey" PRIMARY KEY ("cloud_id");



ALTER TABLE ONLY "bexly"."savings_goals"
    ADD CONSTRAINT "savings_goals_pkey" PRIMARY KEY ("cloud_id");



ALTER TABLE ONLY "bexly"."shared_wallets"
    ADD CONSTRAINT "shared_wallets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "bexly"."shared_wallets"
    ADD CONSTRAINT "shared_wallets_wallet_id_group_id_key" UNIQUE ("wallet_id", "group_id");



ALTER TABLE ONLY "bexly"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("cloud_id");



ALTER TABLE ONLY "bexly"."user_settings"
    ADD CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "bexly"."wallets"
    ADD CONSTRAINT "wallets_pkey" PRIMARY KEY ("cloud_id");



ALTER TABLE ONLY "public"."_prisma_migrations"
    ADD CONSTRAINT "_prisma_migrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fed_profiles"
    ADD CONSTRAINT "actors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."auth_providers"
    ADD CONSTRAINT "auth_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bank_transactions"
    ADD CONSTRAINT "bank_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."delivery_queue"
    ADD CONSTRAINT "delivery_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_codes"
    ADD CONSTRAINT "email_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."linked_bank_accounts"
    ADD CONSTRAINT "linked_bank_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."nonces"
    ADD CONSTRAINT "nonces_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."org_members"
    ADD CONSTRAINT "org_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_transactions"
    ADD CONSTRAINT "payment_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."playfab_accounts"
    ADD CONSTRAINT "playfab_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."playfab_accounts"
    ADD CONSTRAINT "playfab_accounts_user_id_title_id_key" UNIQUE ("user_id", "title_id");



ALTER TABLE ONLY "public"."post_media"
    ADD CONSTRAINT "post_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."remote_actors"
    ADD CONSTRAINT "remote_actors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."session_keys"
    ADD CONSTRAINT "session_keys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."social_follows"
    ADD CONSTRAINT "social_follows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."social_likes"
    ADD CONSTRAINT "social_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stripe_customers"
    ADD CONSTRAINT "stripe_customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."_migrations"
    ADD CONSTRAINT "_migrations_name_key" UNIQUE ("name");



ALTER TABLE ONLY "stripe"."_migrations"
    ADD CONSTRAINT "_migrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."_sync_obj_runs"
    ADD CONSTRAINT "_sync_obj_run_pkey" PRIMARY KEY ("_account_id", "run_started_at", "object");



ALTER TABLE ONLY "stripe"."_sync_runs"
    ADD CONSTRAINT "_sync_run_pkey" PRIMARY KEY ("_account_id", "started_at");



ALTER TABLE ONLY "stripe"."accounts"
    ADD CONSTRAINT "accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."active_entitlements"
    ADD CONSTRAINT "active_entitlements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."charges"
    ADD CONSTRAINT "charges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."checkout_session_line_items"
    ADD CONSTRAINT "checkout_session_line_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."checkout_sessions"
    ADD CONSTRAINT "checkout_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."coupons"
    ADD CONSTRAINT "coupons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."credit_notes"
    ADD CONSTRAINT "credit_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."disputes"
    ADD CONSTRAINT "disputes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."early_fraud_warnings"
    ADD CONSTRAINT "early_fraud_warnings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."exchange_rates_from_usd"
    ADD CONSTRAINT "exchange_rates_from_usd_pkey" PRIMARY KEY ("_account_id", "date", "sell_currency");



ALTER TABLE ONLY "stripe"."features"
    ADD CONSTRAINT "features_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."_managed_webhooks"
    ADD CONSTRAINT "managed_webhooks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."_managed_webhooks"
    ADD CONSTRAINT "managed_webhooks_url_account_unique" UNIQUE ("url", "account_id");



ALTER TABLE ONLY "stripe"."_sync_runs"
    ADD CONSTRAINT "one_active_run_per_account" EXCLUDE USING "btree" ("_account_id" WITH =) WHERE (("closed_at" IS NULL));



ALTER TABLE ONLY "stripe"."payment_intents"
    ADD CONSTRAINT "payment_intents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."payment_methods"
    ADD CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."payouts"
    ADD CONSTRAINT "payouts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."plans"
    ADD CONSTRAINT "plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."prices"
    ADD CONSTRAINT "prices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."refunds"
    ADD CONSTRAINT "refunds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."setup_intents"
    ADD CONSTRAINT "setup_intents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."subscription_item_change_events_v2_beta"
    ADD CONSTRAINT "subscription_item_change_events_v2_beta_pkey" PRIMARY KEY ("_account_id", "event_timestamp", "event_type", "subscription_item_id");



ALTER TABLE ONLY "stripe"."subscription_items"
    ADD CONSTRAINT "subscription_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."subscription_schedules"
    ADD CONSTRAINT "subscription_schedules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "stripe"."tax_ids"
    ADD CONSTRAINT "tax_ids_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."chains"
    ADD CONSTRAINT "chains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."games"
    ADD CONSTRAINT "games_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."marketplace_orders"
    ADD CONSTRAINT "marketplace_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."nft_collections"
    ADD CONSTRAINT "nft_collections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."nfts"
    ADD CONSTRAINT "nfts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."payment_tokens"
    ADD CONSTRAINT "payment_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "web3"."wallet_users"
    ADD CONSTRAINT "wallet_users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_budgets_user_id" ON "bexly"."budgets" USING "btree" ("user_id");



CREATE INDEX "idx_categories_type" ON "bexly"."categories" USING "btree" ("category_type");



CREATE INDEX "idx_categories_user_id" ON "bexly"."categories" USING "btree" ("user_id");



CREATE INDEX "idx_chat_messages_timestamp" ON "bexly"."chat_messages" USING "btree" ("timestamp");



CREATE INDEX "idx_chat_messages_user_id" ON "bexly"."chat_messages" USING "btree" ("user_id");



CREATE INDEX "idx_recurring_is_active" ON "bexly"."recurring_transactions" USING "btree" ("is_active");



CREATE INDEX "idx_recurring_user_id" ON "bexly"."recurring_transactions" USING "btree" ("user_id");



CREATE INDEX "idx_transactions_category_id" ON "bexly"."transactions" USING "btree" ("category_id");



CREATE INDEX "idx_transactions_date" ON "bexly"."transactions" USING "btree" ("transaction_date");



CREATE INDEX "idx_transactions_user_id" ON "bexly"."transactions" USING "btree" ("user_id");



CREATE INDEX "idx_transactions_wallet_id" ON "bexly"."transactions" USING "btree" ("wallet_id");



CREATE INDEX "idx_wallets_is_active" ON "bexly"."wallets" USING "btree" ("is_active");



CREATE INDEX "idx_wallets_user_id" ON "bexly"."wallets" USING "btree" ("user_id");



CREATE INDEX "activities_actor_id_idx" ON "public"."activities" USING "btree" ("actor_id");



CREATE INDEX "activities_created_at_idx" ON "public"."activities" USING "btree" ("created_at");



CREATE INDEX "activities_type_idx" ON "public"."activities" USING "btree" ("type");



CREATE UNIQUE INDEX "activities_uri_key" ON "public"."activities" USING "btree" ("uri");



CREATE UNIQUE INDEX "actors_actor_uri_key" ON "public"."fed_profiles" USING "btree" ("actor_uri");



CREATE UNIQUE INDEX "actors_user_id_key" ON "public"."fed_profiles" USING "btree" ("user_id");



CREATE INDEX "audit_logs_performed_by_idx" ON "public"."audit_logs" USING "btree" ("performed_by");



CREATE INDEX "audit_logs_table_name_record_id_idx" ON "public"."audit_logs" USING "btree" ("table_name", "record_id");



CREATE UNIQUE INDEX "auth_providers_provider_provider_id_key" ON "public"."auth_providers" USING "btree" ("provider", "provider_id");



CREATE INDEX "auth_providers_user_id_idx" ON "public"."auth_providers" USING "btree" ("user_id");



CREATE INDEX "bank_transactions_stripe_account_id_idx" ON "public"."bank_transactions" USING "btree" ("stripe_account_id");



CREATE UNIQUE INDEX "bank_transactions_stripe_transaction_id_key" ON "public"."bank_transactions" USING "btree" ("stripe_transaction_id");



CREATE INDEX "bank_transactions_transacted_at_idx" ON "public"."bank_transactions" USING "btree" ("transacted_at");



CREATE INDEX "bank_transactions_user_id_idx" ON "public"."bank_transactions" USING "btree" ("user_id");



CREATE INDEX "delivery_queue_activity_uri_idx" ON "public"."delivery_queue" USING "btree" ("activity_uri");



CREATE INDEX "delivery_queue_status_next_retry_at_idx" ON "public"."delivery_queue" USING "btree" ("status", "next_retry_at");



CREATE INDEX "email_codes_email_idx" ON "public"."email_codes" USING "btree" ("email");



CREATE INDEX "fed_profiles_preferred_username_idx" ON "public"."fed_profiles" USING "btree" ("preferred_username");



CREATE INDEX "fed_profiles_user_id_idx" ON "public"."fed_profiles" USING "btree" ("user_id");



CREATE INDEX "linked_bank_accounts_status_idx" ON "public"."linked_bank_accounts" USING "btree" ("status");



CREATE UNIQUE INDEX "linked_bank_accounts_stripe_account_id_key" ON "public"."linked_bank_accounts" USING "btree" ("stripe_account_id");



CREATE INDEX "linked_bank_accounts_user_id_idx" ON "public"."linked_bank_accounts" USING "btree" ("user_id");



CREATE UNIQUE INDEX "nonces_address_key" ON "public"."nonces" USING "btree" ("address");



CREATE INDEX "org_invites_email_idx" ON "public"."org_invites" USING "btree" ("email");



CREATE UNIQUE INDEX "org_invites_org_id_email_key" ON "public"."org_invites" USING "btree" ("org_id", "email");



CREATE INDEX "org_invites_token_idx" ON "public"."org_invites" USING "btree" ("token");



CREATE UNIQUE INDEX "org_invites_token_key" ON "public"."org_invites" USING "btree" ("token");



CREATE INDEX "org_members_org_id_idx" ON "public"."org_members" USING "btree" ("org_id");



CREATE UNIQUE INDEX "org_members_org_id_user_id_key" ON "public"."org_members" USING "btree" ("org_id", "user_id");



CREATE INDEX "org_members_user_id_idx" ON "public"."org_members" USING "btree" ("user_id");



CREATE INDEX "organizations_owner_id_idx" ON "public"."organizations" USING "btree" ("owner_id");



CREATE INDEX "organizations_slug_idx" ON "public"."organizations" USING "btree" ("slug");



CREATE UNIQUE INDEX "organizations_slug_key" ON "public"."organizations" USING "btree" ("slug");



CREATE INDEX "payment_transactions_customer_email_idx" ON "public"."payment_transactions" USING "btree" ("customer_email");



CREATE INDEX "payment_transactions_stripe_id_idx" ON "public"."payment_transactions" USING "btree" ("stripe_id");



CREATE UNIQUE INDEX "payment_transactions_stripe_id_key" ON "public"."payment_transactions" USING "btree" ("stripe_id");



CREATE UNIQUE INDEX "playfab_accounts_master_id_key" ON "public"."playfab_accounts" USING "btree" ("master_id");



CREATE INDEX "playfab_accounts_playfab_id_idx" ON "public"."playfab_accounts" USING "btree" ("master_id");



CREATE UNIQUE INDEX "playfab_accounts_user_id_key" ON "public"."playfab_accounts" USING "btree" ("user_id");



CREATE INDEX "post_media_post_id_idx" ON "public"."post_media" USING "btree" ("post_id");



CREATE INDEX "posts_actor_id_idx" ON "public"."posts" USING "btree" ("actor_id");



CREATE INDEX "posts_created_at_idx" ON "public"."posts" USING "btree" ("created_at");



CREATE INDEX "posts_in_reply_to_id_idx" ON "public"."posts" USING "btree" ("in_reply_to_id");



CREATE INDEX "posts_post_type_idx" ON "public"."posts" USING "btree" ("post_type");



CREATE UNIQUE INDEX "posts_uri_key" ON "public"."posts" USING "btree" ("uri");



CREATE INDEX "posts_visibility_idx" ON "public"."posts" USING "btree" ("visibility");



CREATE UNIQUE INDEX "products_product_id_key" ON "public"."products" USING "btree" ("product_id");



CREATE INDEX "profiles_dos_id_idx" ON "public"."profiles" USING "btree" ("dos_id");



CREATE UNIQUE INDEX "profiles_dos_id_key" ON "public"."profiles" USING "btree" ("dos_id");



CREATE INDEX "profiles_email_idx" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "profiles_firebase_uid_idx" ON "public"."profiles" USING "btree" ("firebase_uid");



CREATE UNIQUE INDEX "profiles_firebase_uid_key" ON "public"."profiles" USING "btree" ("firebase_uid");



CREATE UNIQUE INDEX "profiles_openfort_id_key" ON "public"."profiles" USING "btree" ("openfort_id");



CREATE UNIQUE INDEX "profiles_openfort_player_id_key" ON "public"."profiles" USING "btree" ("openfort_player_id");



CREATE INDEX "profiles_playfab_id_idx" ON "public"."profiles" USING "btree" ("playfab_id");



CREATE UNIQUE INDEX "profiles_playfab_id_key" ON "public"."profiles" USING "btree" ("playfab_id");



CREATE INDEX "profiles_referrer_user_id_idx" ON "public"."profiles" USING "btree" ("referrer_user_id");



CREATE UNIQUE INDEX "profiles_username_key" ON "public"."profiles" USING "btree" ("username");



CREATE INDEX "project_members_project_id_idx" ON "public"."project_members" USING "btree" ("project_id");



CREATE UNIQUE INDEX "project_members_project_id_user_id_key" ON "public"."project_members" USING "btree" ("project_id", "user_id");



CREATE INDEX "project_members_user_id_idx" ON "public"."project_members" USING "btree" ("user_id");



CREATE INDEX "projects_org_id_idx" ON "public"."projects" USING "btree" ("org_id");



CREATE UNIQUE INDEX "projects_org_id_slug_key" ON "public"."projects" USING "btree" ("org_id", "slug");



CREATE UNIQUE INDEX "remote_actors_actor_uri_key" ON "public"."remote_actors" USING "btree" ("actor_uri");



CREATE INDEX "remote_actors_domain_idx" ON "public"."remote_actors" USING "btree" ("domain");



CREATE INDEX "remote_actors_preferred_username_domain_idx" ON "public"."remote_actors" USING "btree" ("preferred_username", "domain");



CREATE INDEX "session_keys_playfab_id_is_active_is_deleted_idx" ON "public"."session_keys" USING "btree" ("playfab_id", "is_active", "is_deleted");



CREATE INDEX "session_keys_session_address_idx" ON "public"."session_keys" USING "btree" ("session_address");



CREATE INDEX "session_keys_session_id_idx" ON "public"."session_keys" USING "btree" ("session_id");



CREATE INDEX "session_keys_session_key_idx" ON "public"."session_keys" USING "btree" ("session_key");



CREATE INDEX "session_keys_user_id_idx" ON "public"."session_keys" USING "btree" ("user_id");



CREATE UNIQUE INDEX "social_follows_activity_uri_key" ON "public"."social_follows" USING "btree" ("activity_uri");



CREATE INDEX "social_follows_followee_id_idx" ON "public"."social_follows" USING "btree" ("followee_id");



CREATE UNIQUE INDEX "social_follows_follower_id_followee_id_key" ON "public"."social_follows" USING "btree" ("follower_id", "followee_id");



CREATE INDEX "social_follows_status_idx" ON "public"."social_follows" USING "btree" ("status");



CREATE UNIQUE INDEX "social_likes_activity_uri_key" ON "public"."social_likes" USING "btree" ("activity_uri");



CREATE UNIQUE INDEX "social_likes_actor_id_post_id_key" ON "public"."social_likes" USING "btree" ("actor_id", "post_id");



CREATE INDEX "social_likes_post_id_idx" ON "public"."social_likes" USING "btree" ("post_id");



CREATE UNIQUE INDEX "stripe_customers_stripe_customer_id_key" ON "public"."stripe_customers" USING "btree" ("stripe_customer_id");



CREATE INDEX "stripe_customers_user_id_idx" ON "public"."stripe_customers" USING "btree" ("user_id");



CREATE UNIQUE INDEX "stripe_customers_user_id_key" ON "public"."stripe_customers" USING "btree" ("user_id");



CREATE UNIQUE INDEX "active_entitlements_lookup_key_key" ON "stripe"."active_entitlements" USING "btree" ("lookup_key") WHERE ("lookup_key" IS NOT NULL);



CREATE UNIQUE INDEX "features_lookup_key_key" ON "stripe"."features" USING "btree" ("lookup_key") WHERE ("lookup_key" IS NOT NULL);



CREATE INDEX "idx_accounts_api_key_hashes" ON "stripe"."accounts" USING "gin" ("api_key_hashes");



CREATE INDEX "idx_accounts_business_name" ON "stripe"."accounts" USING "btree" ("business_name");



CREATE INDEX "idx_exchange_rates_from_usd_date" ON "stripe"."exchange_rates_from_usd" USING "btree" ("date");



CREATE INDEX "idx_exchange_rates_from_usd_sell_currency" ON "stripe"."exchange_rates_from_usd" USING "btree" ("sell_currency");



CREATE INDEX "idx_sync_obj_runs_status" ON "stripe"."_sync_obj_runs" USING "btree" ("_account_id", "run_started_at", "status");



CREATE INDEX "idx_sync_runs_account_status" ON "stripe"."_sync_runs" USING "btree" ("_account_id", "closed_at");



CREATE INDEX "stripe_active_entitlements_customer_idx" ON "stripe"."active_entitlements" USING "btree" ("customer");



CREATE INDEX "stripe_active_entitlements_feature_idx" ON "stripe"."active_entitlements" USING "btree" ("feature");



CREATE INDEX "stripe_checkout_session_line_items_price_idx" ON "stripe"."checkout_session_line_items" USING "btree" ("price");



CREATE INDEX "stripe_checkout_session_line_items_session_idx" ON "stripe"."checkout_session_line_items" USING "btree" ("checkout_session");



CREATE INDEX "stripe_checkout_sessions_customer_idx" ON "stripe"."checkout_sessions" USING "btree" ("customer");



CREATE INDEX "stripe_checkout_sessions_invoice_idx" ON "stripe"."checkout_sessions" USING "btree" ("invoice");



CREATE INDEX "stripe_checkout_sessions_payment_intent_idx" ON "stripe"."checkout_sessions" USING "btree" ("payment_intent");



CREATE INDEX "stripe_checkout_sessions_subscription_idx" ON "stripe"."checkout_sessions" USING "btree" ("subscription");



CREATE INDEX "stripe_credit_notes_customer_idx" ON "stripe"."credit_notes" USING "btree" ("customer");



CREATE INDEX "stripe_credit_notes_invoice_idx" ON "stripe"."credit_notes" USING "btree" ("invoice");



CREATE INDEX "stripe_dispute_created_idx" ON "stripe"."disputes" USING "btree" ("created");



CREATE INDEX "stripe_early_fraud_warnings_charge_idx" ON "stripe"."early_fraud_warnings" USING "btree" ("charge");



CREATE INDEX "stripe_early_fraud_warnings_payment_intent_idx" ON "stripe"."early_fraud_warnings" USING "btree" ("payment_intent");



CREATE INDEX "stripe_invoices_customer_idx" ON "stripe"."invoices" USING "btree" ("customer");



CREATE INDEX "stripe_invoices_subscription_idx" ON "stripe"."invoices" USING "btree" ("subscription");



CREATE INDEX "stripe_managed_webhooks_enabled_idx" ON "stripe"."_managed_webhooks" USING "btree" ("enabled");



CREATE INDEX "stripe_managed_webhooks_status_idx" ON "stripe"."_managed_webhooks" USING "btree" ("status");



CREATE INDEX "stripe_payment_intents_customer_idx" ON "stripe"."payment_intents" USING "btree" ("customer");



CREATE INDEX "stripe_payment_intents_invoice_idx" ON "stripe"."payment_intents" USING "btree" ("invoice");



CREATE INDEX "stripe_payment_methods_customer_idx" ON "stripe"."payment_methods" USING "btree" ("customer");



CREATE INDEX "stripe_refunds_charge_idx" ON "stripe"."refunds" USING "btree" ("charge");



CREATE INDEX "stripe_refunds_payment_intent_idx" ON "stripe"."refunds" USING "btree" ("payment_intent");



CREATE INDEX "stripe_reviews_charge_idx" ON "stripe"."reviews" USING "btree" ("charge");



CREATE INDEX "stripe_reviews_payment_intent_idx" ON "stripe"."reviews" USING "btree" ("payment_intent");



CREATE INDEX "stripe_setup_intents_customer_idx" ON "stripe"."setup_intents" USING "btree" ("customer");



CREATE INDEX "stripe_tax_ids_customer_idx" ON "stripe"."tax_ids" USING "btree" ("customer");



CREATE INDEX "chains_chain_id_idx" ON "web3"."chains" USING "btree" ("chain_id");



CREATE UNIQUE INDEX "chains_chain_id_key" ON "web3"."chains" USING "btree" ("chain_id");



CREATE INDEX "chains_enabled_idx" ON "web3"."chains" USING "btree" ("enabled");



CREATE INDEX "games_key_idx" ON "web3"."games" USING "btree" ("key");



CREATE UNIQUE INDEX "games_key_key" ON "web3"."games" USING "btree" ("key");



CREATE INDEX "games_status_idx" ON "web3"."games" USING "btree" ("status");



CREATE INDEX "marketplace_orders_chain_id_idx" ON "web3"."marketplace_orders" USING "btree" ("chain_id");



CREATE INDEX "marketplace_orders_collection_id_idx" ON "web3"."marketplace_orders" USING "btree" ("collection_id");



CREATE INDEX "marketplace_orders_nft_id_idx" ON "web3"."marketplace_orders" USING "btree" ("nft_id");



CREATE UNIQUE INDEX "marketplace_orders_order_hash_key" ON "web3"."marketplace_orders" USING "btree" ("order_hash");



CREATE INDEX "marketplace_orders_owner_address_idx" ON "web3"."marketplace_orders" USING "btree" ("owner_address");



CREATE INDEX "marketplace_orders_price_usd_idx" ON "web3"."marketplace_orders" USING "btree" ("price_usd");



CREATE INDEX "marketplace_orders_status_type_idx" ON "web3"."marketplace_orders" USING "btree" ("status", "type");



CREATE UNIQUE INDEX "nft_collections_chain_id_contract_address_key" ON "web3"."nft_collections" USING "btree" ("chain_id", "contract_address");



CREATE INDEX "nft_collections_chain_id_idx" ON "web3"."nft_collections" USING "btree" ("chain_id");



CREATE INDEX "nft_collections_creator_idx" ON "web3"."nft_collections" USING "btree" ("creator");



CREATE UNIQUE INDEX "nfts_chain_id_contract_address_token_id_key" ON "web3"."nfts" USING "btree" ("chain_id", "contract_address", "token_id");



CREATE INDEX "nfts_chain_id_idx" ON "web3"."nfts" USING "btree" ("chain_id");



CREATE INDEX "nfts_collection_id_idx" ON "web3"."nfts" USING "btree" ("collection_id");



CREATE INDEX "nfts_contract_address_idx" ON "web3"."nfts" USING "btree" ("contract_address");



CREATE INDEX "nfts_market_type_idx" ON "web3"."nfts" USING "btree" ("market_type");



CREATE INDEX "nfts_price_idx" ON "web3"."nfts" USING "btree" ("price");



CREATE UNIQUE INDEX "payment_tokens_chain_id_address_key" ON "web3"."payment_tokens" USING "btree" ("chain_id", "address");



CREATE INDEX "payment_tokens_chain_id_idx" ON "web3"."payment_tokens" USING "btree" ("chain_id");



CREATE INDEX "payment_tokens_symbol_idx" ON "web3"."payment_tokens" USING "btree" ("symbol");



CREATE INDEX "wallet_users_address_idx" ON "web3"."wallet_users" USING "btree" ("address");



CREATE UNIQUE INDEX "wallet_users_address_key" ON "web3"."wallet_users" USING "btree" ("address");



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."_managed_webhooks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at_metadata"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."_sync_obj_runs" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at_metadata"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."_sync_runs" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at_metadata"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."accounts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."active_entitlements" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."charges" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."checkout_session_line_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."checkout_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."coupons" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."customers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."disputes" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."early_fraud_warnings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."events" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."exchange_rates_from_usd" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."features" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."invoices" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."payouts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."plans" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."prices" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."products" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."refunds" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."subscription_item_change_events_v2_beta" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "stripe"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "bexly"."budget_alerts"
    ADD CONSTRAINT "budget_alerts_budget_id_fkey" FOREIGN KEY ("budget_id") REFERENCES "bexly"."budgets"("cloud_id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."budgets"
    ADD CONSTRAINT "budgets_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "bexly"."categories"("cloud_id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."budgets"
    ADD CONSTRAINT "budgets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."categories"
    ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "bexly"."categories"("cloud_id") ON DELETE SET NULL;



ALTER TABLE ONLY "bexly"."categories"
    ADD CONSTRAINT "categories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."chat_messages"
    ADD CONSTRAINT "chat_messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."checklist_items"
    ADD CONSTRAINT "checklist_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."family_groups"
    ADD CONSTRAINT "family_groups_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."family_members"
    ADD CONSTRAINT "family_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "bexly"."family_groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."family_members"
    ADD CONSTRAINT "family_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."recurring_transactions"
    ADD CONSTRAINT "recurring_transactions_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "bexly"."categories"("cloud_id") ON DELETE SET NULL;



ALTER TABLE ONLY "bexly"."recurring_transactions"
    ADD CONSTRAINT "recurring_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."recurring_transactions"
    ADD CONSTRAINT "recurring_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "bexly"."wallets"("cloud_id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."savings_goals"
    ADD CONSTRAINT "savings_goals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."savings_goals"
    ADD CONSTRAINT "savings_goals_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "bexly"."wallets"("cloud_id") ON DELETE SET NULL;



ALTER TABLE ONLY "bexly"."shared_wallets"
    ADD CONSTRAINT "shared_wallets_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "bexly"."family_groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."shared_wallets"
    ADD CONSTRAINT "shared_wallets_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "bexly"."wallets"("cloud_id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."transactions"
    ADD CONSTRAINT "transactions_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "bexly"."categories"("cloud_id") ON DELETE SET NULL;



ALTER TABLE ONLY "bexly"."transactions"
    ADD CONSTRAINT "transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."transactions"
    ADD CONSTRAINT "transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "bexly"."wallets"("cloud_id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."user_settings"
    ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "bexly"."wallets"
    ADD CONSTRAINT "wallets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activities"
    ADD CONSTRAINT "activities_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."fed_profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fed_profiles"
    ADD CONSTRAINT "actors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."auth_providers"
    ADD CONSTRAINT "auth_providers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bank_transactions"
    ADD CONSTRAINT "bank_transactions_stripe_account_id_fkey" FOREIGN KEY ("stripe_account_id") REFERENCES "public"."linked_bank_accounts"("stripe_account_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bank_transactions"
    ADD CONSTRAINT "bank_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."linked_bank_accounts"
    ADD CONSTRAINT "linked_bank_accounts_stripe_customer_id_fkey" FOREIGN KEY ("stripe_customer_id") REFERENCES "public"."stripe_customers"("stripe_customer_id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."linked_bank_accounts"
    ADD CONSTRAINT "linked_bank_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."org_invites"
    ADD CONSTRAINT "org_invites_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."org_members"
    ADD CONSTRAINT "org_members_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."org_members"
    ADD CONSTRAINT "org_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."playfab_accounts"
    ADD CONSTRAINT "playfab_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_media"
    ADD CONSTRAINT "post_media_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."fed_profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_in_reply_to_id_fkey" FOREIGN KEY ("in_reply_to_id") REFERENCES "public"."posts"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_keys"
    ADD CONSTRAINT "session_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."social_follows"
    ADD CONSTRAINT "social_follows_followee_id_fkey" FOREIGN KEY ("followee_id") REFERENCES "public"."fed_profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."social_follows"
    ADD CONSTRAINT "social_follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."fed_profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."social_likes"
    ADD CONSTRAINT "social_likes_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."fed_profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."social_likes"
    ADD CONSTRAINT "social_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stripe_customers"
    ADD CONSTRAINT "stripe_customers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("user_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "stripe"."active_entitlements"
    ADD CONSTRAINT "fk_active_entitlements_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."charges"
    ADD CONSTRAINT "fk_charges_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."checkout_session_line_items"
    ADD CONSTRAINT "fk_checkout_session_line_items_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."checkout_sessions"
    ADD CONSTRAINT "fk_checkout_sessions_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."credit_notes"
    ADD CONSTRAINT "fk_credit_notes_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."customers"
    ADD CONSTRAINT "fk_customers_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."disputes"
    ADD CONSTRAINT "fk_disputes_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."early_fraud_warnings"
    ADD CONSTRAINT "fk_early_fraud_warnings_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."exchange_rates_from_usd"
    ADD CONSTRAINT "fk_exchange_rates_from_usd_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."features"
    ADD CONSTRAINT "fk_features_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."invoices"
    ADD CONSTRAINT "fk_invoices_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."_managed_webhooks"
    ADD CONSTRAINT "fk_managed_webhooks_account" FOREIGN KEY ("account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."payment_intents"
    ADD CONSTRAINT "fk_payment_intents_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."payment_methods"
    ADD CONSTRAINT "fk_payment_methods_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."plans"
    ADD CONSTRAINT "fk_plans_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."prices"
    ADD CONSTRAINT "fk_prices_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."products"
    ADD CONSTRAINT "fk_products_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."refunds"
    ADD CONSTRAINT "fk_refunds_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."reviews"
    ADD CONSTRAINT "fk_reviews_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."setup_intents"
    ADD CONSTRAINT "fk_setup_intents_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."subscription_item_change_events_v2_beta"
    ADD CONSTRAINT "fk_subscription_item_change_events_v2_beta_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."subscription_items"
    ADD CONSTRAINT "fk_subscription_items_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."subscription_schedules"
    ADD CONSTRAINT "fk_subscription_schedules_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."subscriptions"
    ADD CONSTRAINT "fk_subscriptions_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."_sync_obj_runs"
    ADD CONSTRAINT "fk_sync_obj_runs_parent" FOREIGN KEY ("_account_id", "run_started_at") REFERENCES "stripe"."_sync_runs"("_account_id", "started_at");



ALTER TABLE ONLY "stripe"."_sync_runs"
    ADD CONSTRAINT "fk_sync_run_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "stripe"."tax_ids"
    ADD CONSTRAINT "fk_tax_ids_account" FOREIGN KEY ("_account_id") REFERENCES "stripe"."accounts"("id");



ALTER TABLE ONLY "web3"."marketplace_orders"
    ADD CONSTRAINT "marketplace_orders_chain_id_fkey" FOREIGN KEY ("chain_id") REFERENCES "web3"."chains"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."marketplace_orders"
    ADD CONSTRAINT "marketplace_orders_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "web3"."nft_collections"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."marketplace_orders"
    ADD CONSTRAINT "marketplace_orders_nft_id_fkey" FOREIGN KEY ("nft_id") REFERENCES "web3"."nfts"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."marketplace_orders"
    ADD CONSTRAINT "marketplace_orders_owner_address_fkey" FOREIGN KEY ("owner_address") REFERENCES "web3"."wallet_users"("address") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."nft_collections"
    ADD CONSTRAINT "nft_collections_chain_id_fkey" FOREIGN KEY ("chain_id") REFERENCES "web3"."chains"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."nfts"
    ADD CONSTRAINT "nfts_chain_id_fkey" FOREIGN KEY ("chain_id") REFERENCES "web3"."chains"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."nfts"
    ADD CONSTRAINT "nfts_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "web3"."nft_collections"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "web3"."payment_tokens"
    ADD CONSTRAINT "payment_tokens_chain_id_fkey" FOREIGN KEY ("chain_id") REFERENCES "web3"."chains"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



CREATE POLICY "Users can CRUD their own budgets" ON "bexly"."budgets" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own categories" ON "bexly"."categories" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own chat messages" ON "bexly"."chat_messages" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own checklist items" ON "bexly"."checklist_items" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own notifications" ON "bexly"."notifications" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own recurring transactions" ON "bexly"."recurring_transactions" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own savings goals" ON "bexly"."savings_goals" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own settings" ON "bexly"."user_settings" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own transactions" ON "bexly"."transactions" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can CRUD their own wallets" ON "bexly"."wallets" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view budget alerts for their budgets" ON "bexly"."budget_alerts" FOR SELECT TO "authenticated" USING (("budget_id" IN ( SELECT "budgets"."cloud_id"
   FROM "bexly"."budgets"
  WHERE ("budgets"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view family groups they own" ON "bexly"."family_groups" TO "authenticated" USING (("owner_id" = "auth"."uid"())) WITH CHECK (("owner_id" = "auth"."uid"()));



CREATE POLICY "Users can view family members in their groups" ON "bexly"."family_members" FOR SELECT TO "authenticated" USING (("group_id" IN ( SELECT "family_groups"."id"
   FROM "bexly"."family_groups"
  WHERE ("family_groups"."owner_id" = "auth"."uid"()))));



CREATE POLICY "Users can view shared wallets in their groups" ON "bexly"."shared_wallets" FOR SELECT TO "authenticated" USING (("group_id" IN ( SELECT "family_groups"."id"
   FROM "bexly"."family_groups"
  WHERE ("family_groups"."owner_id" = "auth"."uid"()))));



ALTER TABLE "bexly"."budget_alerts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."budgets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."chat_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."checklist_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."family_groups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."family_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."recurring_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."savings_goals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."shared_wallets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."user_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "bexly"."wallets" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "bexly" TO "anon";
GRANT USAGE ON SCHEMA "bexly" TO "authenticated";









REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;























































































































































































GRANT ALL ON TABLE "bexly"."budget_alerts" TO "anon";
GRANT ALL ON TABLE "bexly"."budget_alerts" TO "authenticated";



GRANT ALL ON TABLE "bexly"."budgets" TO "anon";
GRANT ALL ON TABLE "bexly"."budgets" TO "authenticated";



GRANT ALL ON TABLE "bexly"."categories" TO "anon";
GRANT ALL ON TABLE "bexly"."categories" TO "authenticated";



GRANT ALL ON TABLE "bexly"."chat_messages" TO "anon";
GRANT ALL ON TABLE "bexly"."chat_messages" TO "authenticated";



GRANT ALL ON TABLE "bexly"."checklist_items" TO "anon";
GRANT ALL ON TABLE "bexly"."checklist_items" TO "authenticated";



GRANT ALL ON TABLE "bexly"."family_groups" TO "anon";
GRANT ALL ON TABLE "bexly"."family_groups" TO "authenticated";



GRANT ALL ON TABLE "bexly"."family_members" TO "anon";
GRANT ALL ON TABLE "bexly"."family_members" TO "authenticated";



GRANT ALL ON TABLE "bexly"."notifications" TO "anon";
GRANT ALL ON TABLE "bexly"."notifications" TO "authenticated";



GRANT ALL ON TABLE "bexly"."recurring_transactions" TO "anon";
GRANT ALL ON TABLE "bexly"."recurring_transactions" TO "authenticated";



GRANT ALL ON TABLE "bexly"."savings_goals" TO "anon";
GRANT ALL ON TABLE "bexly"."savings_goals" TO "authenticated";



GRANT ALL ON TABLE "bexly"."shared_wallets" TO "anon";
GRANT ALL ON TABLE "bexly"."shared_wallets" TO "authenticated";



GRANT ALL ON TABLE "bexly"."transactions" TO "anon";
GRANT ALL ON TABLE "bexly"."transactions" TO "authenticated";



GRANT ALL ON TABLE "bexly"."user_settings" TO "anon";
GRANT ALL ON TABLE "bexly"."user_settings" TO "authenticated";



GRANT ALL ON TABLE "bexly"."wallets" TO "anon";
GRANT ALL ON TABLE "bexly"."wallets" TO "authenticated";





















ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "bexly" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "bexly" GRANT ALL ON SEQUENCES TO "authenticated";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "bexly" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "bexly" GRANT ALL ON TABLES TO "authenticated";




























revoke delete on table "public"."_prisma_migrations" from "anon";

revoke insert on table "public"."_prisma_migrations" from "anon";

revoke references on table "public"."_prisma_migrations" from "anon";

revoke select on table "public"."_prisma_migrations" from "anon";

revoke trigger on table "public"."_prisma_migrations" from "anon";

revoke truncate on table "public"."_prisma_migrations" from "anon";

revoke update on table "public"."_prisma_migrations" from "anon";

revoke delete on table "public"."_prisma_migrations" from "authenticated";

revoke insert on table "public"."_prisma_migrations" from "authenticated";

revoke references on table "public"."_prisma_migrations" from "authenticated";

revoke select on table "public"."_prisma_migrations" from "authenticated";

revoke trigger on table "public"."_prisma_migrations" from "authenticated";

revoke truncate on table "public"."_prisma_migrations" from "authenticated";

revoke update on table "public"."_prisma_migrations" from "authenticated";

revoke delete on table "public"."_prisma_migrations" from "service_role";

revoke insert on table "public"."_prisma_migrations" from "service_role";

revoke references on table "public"."_prisma_migrations" from "service_role";

revoke select on table "public"."_prisma_migrations" from "service_role";

revoke trigger on table "public"."_prisma_migrations" from "service_role";

revoke truncate on table "public"."_prisma_migrations" from "service_role";

revoke update on table "public"."_prisma_migrations" from "service_role";

revoke delete on table "public"."activities" from "anon";

revoke insert on table "public"."activities" from "anon";

revoke references on table "public"."activities" from "anon";

revoke select on table "public"."activities" from "anon";

revoke trigger on table "public"."activities" from "anon";

revoke truncate on table "public"."activities" from "anon";

revoke update on table "public"."activities" from "anon";

revoke delete on table "public"."activities" from "authenticated";

revoke insert on table "public"."activities" from "authenticated";

revoke references on table "public"."activities" from "authenticated";

revoke select on table "public"."activities" from "authenticated";

revoke trigger on table "public"."activities" from "authenticated";

revoke truncate on table "public"."activities" from "authenticated";

revoke update on table "public"."activities" from "authenticated";

revoke delete on table "public"."activities" from "service_role";

revoke insert on table "public"."activities" from "service_role";

revoke references on table "public"."activities" from "service_role";

revoke select on table "public"."activities" from "service_role";

revoke trigger on table "public"."activities" from "service_role";

revoke truncate on table "public"."activities" from "service_role";

revoke update on table "public"."activities" from "service_role";

revoke delete on table "public"."audit_logs" from "anon";

revoke insert on table "public"."audit_logs" from "anon";

revoke references on table "public"."audit_logs" from "anon";

revoke select on table "public"."audit_logs" from "anon";

revoke trigger on table "public"."audit_logs" from "anon";

revoke truncate on table "public"."audit_logs" from "anon";

revoke update on table "public"."audit_logs" from "anon";

revoke delete on table "public"."audit_logs" from "authenticated";

revoke insert on table "public"."audit_logs" from "authenticated";

revoke references on table "public"."audit_logs" from "authenticated";

revoke select on table "public"."audit_logs" from "authenticated";

revoke trigger on table "public"."audit_logs" from "authenticated";

revoke truncate on table "public"."audit_logs" from "authenticated";

revoke update on table "public"."audit_logs" from "authenticated";

revoke delete on table "public"."audit_logs" from "service_role";

revoke insert on table "public"."audit_logs" from "service_role";

revoke references on table "public"."audit_logs" from "service_role";

revoke select on table "public"."audit_logs" from "service_role";

revoke trigger on table "public"."audit_logs" from "service_role";

revoke truncate on table "public"."audit_logs" from "service_role";

revoke update on table "public"."audit_logs" from "service_role";

revoke delete on table "public"."auth_providers" from "anon";

revoke insert on table "public"."auth_providers" from "anon";

revoke references on table "public"."auth_providers" from "anon";

revoke select on table "public"."auth_providers" from "anon";

revoke trigger on table "public"."auth_providers" from "anon";

revoke truncate on table "public"."auth_providers" from "anon";

revoke update on table "public"."auth_providers" from "anon";

revoke delete on table "public"."auth_providers" from "authenticated";

revoke insert on table "public"."auth_providers" from "authenticated";

revoke references on table "public"."auth_providers" from "authenticated";

revoke select on table "public"."auth_providers" from "authenticated";

revoke trigger on table "public"."auth_providers" from "authenticated";

revoke truncate on table "public"."auth_providers" from "authenticated";

revoke update on table "public"."auth_providers" from "authenticated";

revoke delete on table "public"."auth_providers" from "service_role";

revoke insert on table "public"."auth_providers" from "service_role";

revoke references on table "public"."auth_providers" from "service_role";

revoke select on table "public"."auth_providers" from "service_role";

revoke trigger on table "public"."auth_providers" from "service_role";

revoke truncate on table "public"."auth_providers" from "service_role";

revoke update on table "public"."auth_providers" from "service_role";

revoke delete on table "public"."bank_transactions" from "anon";

revoke insert on table "public"."bank_transactions" from "anon";

revoke references on table "public"."bank_transactions" from "anon";

revoke select on table "public"."bank_transactions" from "anon";

revoke trigger on table "public"."bank_transactions" from "anon";

revoke truncate on table "public"."bank_transactions" from "anon";

revoke update on table "public"."bank_transactions" from "anon";

revoke delete on table "public"."bank_transactions" from "authenticated";

revoke insert on table "public"."bank_transactions" from "authenticated";

revoke references on table "public"."bank_transactions" from "authenticated";

revoke select on table "public"."bank_transactions" from "authenticated";

revoke trigger on table "public"."bank_transactions" from "authenticated";

revoke truncate on table "public"."bank_transactions" from "authenticated";

revoke update on table "public"."bank_transactions" from "authenticated";

revoke delete on table "public"."bank_transactions" from "service_role";

revoke insert on table "public"."bank_transactions" from "service_role";

revoke references on table "public"."bank_transactions" from "service_role";

revoke select on table "public"."bank_transactions" from "service_role";

revoke trigger on table "public"."bank_transactions" from "service_role";

revoke truncate on table "public"."bank_transactions" from "service_role";

revoke update on table "public"."bank_transactions" from "service_role";

revoke delete on table "public"."delivery_queue" from "anon";

revoke insert on table "public"."delivery_queue" from "anon";

revoke references on table "public"."delivery_queue" from "anon";

revoke select on table "public"."delivery_queue" from "anon";

revoke trigger on table "public"."delivery_queue" from "anon";

revoke truncate on table "public"."delivery_queue" from "anon";

revoke update on table "public"."delivery_queue" from "anon";

revoke delete on table "public"."delivery_queue" from "authenticated";

revoke insert on table "public"."delivery_queue" from "authenticated";

revoke references on table "public"."delivery_queue" from "authenticated";

revoke select on table "public"."delivery_queue" from "authenticated";

revoke trigger on table "public"."delivery_queue" from "authenticated";

revoke truncate on table "public"."delivery_queue" from "authenticated";

revoke update on table "public"."delivery_queue" from "authenticated";

revoke delete on table "public"."delivery_queue" from "service_role";

revoke insert on table "public"."delivery_queue" from "service_role";

revoke references on table "public"."delivery_queue" from "service_role";

revoke select on table "public"."delivery_queue" from "service_role";

revoke trigger on table "public"."delivery_queue" from "service_role";

revoke truncate on table "public"."delivery_queue" from "service_role";

revoke update on table "public"."delivery_queue" from "service_role";

revoke delete on table "public"."email_codes" from "anon";

revoke insert on table "public"."email_codes" from "anon";

revoke references on table "public"."email_codes" from "anon";

revoke select on table "public"."email_codes" from "anon";

revoke trigger on table "public"."email_codes" from "anon";

revoke truncate on table "public"."email_codes" from "anon";

revoke update on table "public"."email_codes" from "anon";

revoke delete on table "public"."email_codes" from "authenticated";

revoke insert on table "public"."email_codes" from "authenticated";

revoke references on table "public"."email_codes" from "authenticated";

revoke select on table "public"."email_codes" from "authenticated";

revoke trigger on table "public"."email_codes" from "authenticated";

revoke truncate on table "public"."email_codes" from "authenticated";

revoke update on table "public"."email_codes" from "authenticated";

revoke delete on table "public"."email_codes" from "service_role";

revoke insert on table "public"."email_codes" from "service_role";

revoke references on table "public"."email_codes" from "service_role";

revoke select on table "public"."email_codes" from "service_role";

revoke trigger on table "public"."email_codes" from "service_role";

revoke truncate on table "public"."email_codes" from "service_role";

revoke update on table "public"."email_codes" from "service_role";

revoke delete on table "public"."fed_profiles" from "anon";

revoke insert on table "public"."fed_profiles" from "anon";

revoke references on table "public"."fed_profiles" from "anon";

revoke select on table "public"."fed_profiles" from "anon";

revoke trigger on table "public"."fed_profiles" from "anon";

revoke truncate on table "public"."fed_profiles" from "anon";

revoke update on table "public"."fed_profiles" from "anon";

revoke delete on table "public"."fed_profiles" from "authenticated";

revoke insert on table "public"."fed_profiles" from "authenticated";

revoke references on table "public"."fed_profiles" from "authenticated";

revoke select on table "public"."fed_profiles" from "authenticated";

revoke trigger on table "public"."fed_profiles" from "authenticated";

revoke truncate on table "public"."fed_profiles" from "authenticated";

revoke update on table "public"."fed_profiles" from "authenticated";

revoke delete on table "public"."fed_profiles" from "service_role";

revoke insert on table "public"."fed_profiles" from "service_role";

revoke references on table "public"."fed_profiles" from "service_role";

revoke select on table "public"."fed_profiles" from "service_role";

revoke trigger on table "public"."fed_profiles" from "service_role";

revoke truncate on table "public"."fed_profiles" from "service_role";

revoke update on table "public"."fed_profiles" from "service_role";

revoke delete on table "public"."linked_bank_accounts" from "anon";

revoke insert on table "public"."linked_bank_accounts" from "anon";

revoke references on table "public"."linked_bank_accounts" from "anon";

revoke select on table "public"."linked_bank_accounts" from "anon";

revoke trigger on table "public"."linked_bank_accounts" from "anon";

revoke truncate on table "public"."linked_bank_accounts" from "anon";

revoke update on table "public"."linked_bank_accounts" from "anon";

revoke delete on table "public"."linked_bank_accounts" from "authenticated";

revoke insert on table "public"."linked_bank_accounts" from "authenticated";

revoke references on table "public"."linked_bank_accounts" from "authenticated";

revoke select on table "public"."linked_bank_accounts" from "authenticated";

revoke trigger on table "public"."linked_bank_accounts" from "authenticated";

revoke truncate on table "public"."linked_bank_accounts" from "authenticated";

revoke update on table "public"."linked_bank_accounts" from "authenticated";

revoke delete on table "public"."linked_bank_accounts" from "service_role";

revoke insert on table "public"."linked_bank_accounts" from "service_role";

revoke references on table "public"."linked_bank_accounts" from "service_role";

revoke select on table "public"."linked_bank_accounts" from "service_role";

revoke trigger on table "public"."linked_bank_accounts" from "service_role";

revoke truncate on table "public"."linked_bank_accounts" from "service_role";

revoke update on table "public"."linked_bank_accounts" from "service_role";

revoke delete on table "public"."nonces" from "anon";

revoke insert on table "public"."nonces" from "anon";

revoke references on table "public"."nonces" from "anon";

revoke select on table "public"."nonces" from "anon";

revoke trigger on table "public"."nonces" from "anon";

revoke truncate on table "public"."nonces" from "anon";

revoke update on table "public"."nonces" from "anon";

revoke delete on table "public"."nonces" from "authenticated";

revoke insert on table "public"."nonces" from "authenticated";

revoke references on table "public"."nonces" from "authenticated";

revoke select on table "public"."nonces" from "authenticated";

revoke trigger on table "public"."nonces" from "authenticated";

revoke truncate on table "public"."nonces" from "authenticated";

revoke update on table "public"."nonces" from "authenticated";

revoke delete on table "public"."nonces" from "service_role";

revoke insert on table "public"."nonces" from "service_role";

revoke references on table "public"."nonces" from "service_role";

revoke select on table "public"."nonces" from "service_role";

revoke trigger on table "public"."nonces" from "service_role";

revoke truncate on table "public"."nonces" from "service_role";

revoke update on table "public"."nonces" from "service_role";

revoke delete on table "public"."org_invites" from "anon";

revoke insert on table "public"."org_invites" from "anon";

revoke references on table "public"."org_invites" from "anon";

revoke select on table "public"."org_invites" from "anon";

revoke trigger on table "public"."org_invites" from "anon";

revoke truncate on table "public"."org_invites" from "anon";

revoke update on table "public"."org_invites" from "anon";

revoke delete on table "public"."org_invites" from "authenticated";

revoke insert on table "public"."org_invites" from "authenticated";

revoke references on table "public"."org_invites" from "authenticated";

revoke select on table "public"."org_invites" from "authenticated";

revoke trigger on table "public"."org_invites" from "authenticated";

revoke truncate on table "public"."org_invites" from "authenticated";

revoke update on table "public"."org_invites" from "authenticated";

revoke delete on table "public"."org_invites" from "service_role";

revoke insert on table "public"."org_invites" from "service_role";

revoke references on table "public"."org_invites" from "service_role";

revoke select on table "public"."org_invites" from "service_role";

revoke trigger on table "public"."org_invites" from "service_role";

revoke truncate on table "public"."org_invites" from "service_role";

revoke update on table "public"."org_invites" from "service_role";

revoke delete on table "public"."org_members" from "anon";

revoke insert on table "public"."org_members" from "anon";

revoke references on table "public"."org_members" from "anon";

revoke select on table "public"."org_members" from "anon";

revoke trigger on table "public"."org_members" from "anon";

revoke truncate on table "public"."org_members" from "anon";

revoke update on table "public"."org_members" from "anon";

revoke delete on table "public"."org_members" from "authenticated";

revoke insert on table "public"."org_members" from "authenticated";

revoke references on table "public"."org_members" from "authenticated";

revoke select on table "public"."org_members" from "authenticated";

revoke trigger on table "public"."org_members" from "authenticated";

revoke truncate on table "public"."org_members" from "authenticated";

revoke update on table "public"."org_members" from "authenticated";

revoke delete on table "public"."org_members" from "service_role";

revoke insert on table "public"."org_members" from "service_role";

revoke references on table "public"."org_members" from "service_role";

revoke select on table "public"."org_members" from "service_role";

revoke trigger on table "public"."org_members" from "service_role";

revoke truncate on table "public"."org_members" from "service_role";

revoke update on table "public"."org_members" from "service_role";

revoke delete on table "public"."organizations" from "anon";

revoke insert on table "public"."organizations" from "anon";

revoke references on table "public"."organizations" from "anon";

revoke select on table "public"."organizations" from "anon";

revoke trigger on table "public"."organizations" from "anon";

revoke truncate on table "public"."organizations" from "anon";

revoke update on table "public"."organizations" from "anon";

revoke delete on table "public"."organizations" from "authenticated";

revoke insert on table "public"."organizations" from "authenticated";

revoke references on table "public"."organizations" from "authenticated";

revoke select on table "public"."organizations" from "authenticated";

revoke trigger on table "public"."organizations" from "authenticated";

revoke truncate on table "public"."organizations" from "authenticated";

revoke update on table "public"."organizations" from "authenticated";

revoke delete on table "public"."organizations" from "service_role";

revoke insert on table "public"."organizations" from "service_role";

revoke references on table "public"."organizations" from "service_role";

revoke select on table "public"."organizations" from "service_role";

revoke trigger on table "public"."organizations" from "service_role";

revoke truncate on table "public"."organizations" from "service_role";

revoke update on table "public"."organizations" from "service_role";

revoke delete on table "public"."payment_transactions" from "anon";

revoke insert on table "public"."payment_transactions" from "anon";

revoke references on table "public"."payment_transactions" from "anon";

revoke select on table "public"."payment_transactions" from "anon";

revoke trigger on table "public"."payment_transactions" from "anon";

revoke truncate on table "public"."payment_transactions" from "anon";

revoke update on table "public"."payment_transactions" from "anon";

revoke delete on table "public"."payment_transactions" from "authenticated";

revoke insert on table "public"."payment_transactions" from "authenticated";

revoke references on table "public"."payment_transactions" from "authenticated";

revoke select on table "public"."payment_transactions" from "authenticated";

revoke trigger on table "public"."payment_transactions" from "authenticated";

revoke truncate on table "public"."payment_transactions" from "authenticated";

revoke update on table "public"."payment_transactions" from "authenticated";

revoke delete on table "public"."payment_transactions" from "service_role";

revoke insert on table "public"."payment_transactions" from "service_role";

revoke references on table "public"."payment_transactions" from "service_role";

revoke select on table "public"."payment_transactions" from "service_role";

revoke trigger on table "public"."payment_transactions" from "service_role";

revoke truncate on table "public"."payment_transactions" from "service_role";

revoke update on table "public"."payment_transactions" from "service_role";

revoke delete on table "public"."playfab_accounts" from "anon";

revoke insert on table "public"."playfab_accounts" from "anon";

revoke references on table "public"."playfab_accounts" from "anon";

revoke select on table "public"."playfab_accounts" from "anon";

revoke trigger on table "public"."playfab_accounts" from "anon";

revoke truncate on table "public"."playfab_accounts" from "anon";

revoke update on table "public"."playfab_accounts" from "anon";

revoke delete on table "public"."playfab_accounts" from "authenticated";

revoke insert on table "public"."playfab_accounts" from "authenticated";

revoke references on table "public"."playfab_accounts" from "authenticated";

revoke select on table "public"."playfab_accounts" from "authenticated";

revoke trigger on table "public"."playfab_accounts" from "authenticated";

revoke truncate on table "public"."playfab_accounts" from "authenticated";

revoke update on table "public"."playfab_accounts" from "authenticated";

revoke delete on table "public"."playfab_accounts" from "service_role";

revoke insert on table "public"."playfab_accounts" from "service_role";

revoke references on table "public"."playfab_accounts" from "service_role";

revoke select on table "public"."playfab_accounts" from "service_role";

revoke trigger on table "public"."playfab_accounts" from "service_role";

revoke truncate on table "public"."playfab_accounts" from "service_role";

revoke update on table "public"."playfab_accounts" from "service_role";

revoke delete on table "public"."post_media" from "anon";

revoke insert on table "public"."post_media" from "anon";

revoke references on table "public"."post_media" from "anon";

revoke select on table "public"."post_media" from "anon";

revoke trigger on table "public"."post_media" from "anon";

revoke truncate on table "public"."post_media" from "anon";

revoke update on table "public"."post_media" from "anon";

revoke delete on table "public"."post_media" from "authenticated";

revoke insert on table "public"."post_media" from "authenticated";

revoke references on table "public"."post_media" from "authenticated";

revoke select on table "public"."post_media" from "authenticated";

revoke trigger on table "public"."post_media" from "authenticated";

revoke truncate on table "public"."post_media" from "authenticated";

revoke update on table "public"."post_media" from "authenticated";

revoke delete on table "public"."post_media" from "service_role";

revoke insert on table "public"."post_media" from "service_role";

revoke references on table "public"."post_media" from "service_role";

revoke select on table "public"."post_media" from "service_role";

revoke trigger on table "public"."post_media" from "service_role";

revoke truncate on table "public"."post_media" from "service_role";

revoke update on table "public"."post_media" from "service_role";

revoke delete on table "public"."posts" from "anon";

revoke insert on table "public"."posts" from "anon";

revoke references on table "public"."posts" from "anon";

revoke select on table "public"."posts" from "anon";

revoke trigger on table "public"."posts" from "anon";

revoke truncate on table "public"."posts" from "anon";

revoke update on table "public"."posts" from "anon";

revoke delete on table "public"."posts" from "authenticated";

revoke insert on table "public"."posts" from "authenticated";

revoke references on table "public"."posts" from "authenticated";

revoke select on table "public"."posts" from "authenticated";

revoke trigger on table "public"."posts" from "authenticated";

revoke truncate on table "public"."posts" from "authenticated";

revoke update on table "public"."posts" from "authenticated";

revoke delete on table "public"."posts" from "service_role";

revoke insert on table "public"."posts" from "service_role";

revoke references on table "public"."posts" from "service_role";

revoke select on table "public"."posts" from "service_role";

revoke trigger on table "public"."posts" from "service_role";

revoke truncate on table "public"."posts" from "service_role";

revoke update on table "public"."posts" from "service_role";

revoke delete on table "public"."products" from "anon";

revoke insert on table "public"."products" from "anon";

revoke references on table "public"."products" from "anon";

revoke select on table "public"."products" from "anon";

revoke trigger on table "public"."products" from "anon";

revoke truncate on table "public"."products" from "anon";

revoke update on table "public"."products" from "anon";

revoke delete on table "public"."products" from "authenticated";

revoke insert on table "public"."products" from "authenticated";

revoke references on table "public"."products" from "authenticated";

revoke select on table "public"."products" from "authenticated";

revoke trigger on table "public"."products" from "authenticated";

revoke truncate on table "public"."products" from "authenticated";

revoke update on table "public"."products" from "authenticated";

revoke delete on table "public"."products" from "service_role";

revoke insert on table "public"."products" from "service_role";

revoke references on table "public"."products" from "service_role";

revoke select on table "public"."products" from "service_role";

revoke trigger on table "public"."products" from "service_role";

revoke truncate on table "public"."products" from "service_role";

revoke update on table "public"."products" from "service_role";

revoke delete on table "public"."profiles" from "anon";

revoke insert on table "public"."profiles" from "anon";

revoke references on table "public"."profiles" from "anon";

revoke select on table "public"."profiles" from "anon";

revoke trigger on table "public"."profiles" from "anon";

revoke truncate on table "public"."profiles" from "anon";

revoke update on table "public"."profiles" from "anon";

revoke delete on table "public"."profiles" from "authenticated";

revoke insert on table "public"."profiles" from "authenticated";

revoke references on table "public"."profiles" from "authenticated";

revoke select on table "public"."profiles" from "authenticated";

revoke trigger on table "public"."profiles" from "authenticated";

revoke truncate on table "public"."profiles" from "authenticated";

revoke update on table "public"."profiles" from "authenticated";

revoke delete on table "public"."profiles" from "service_role";

revoke insert on table "public"."profiles" from "service_role";

revoke references on table "public"."profiles" from "service_role";

revoke select on table "public"."profiles" from "service_role";

revoke trigger on table "public"."profiles" from "service_role";

revoke truncate on table "public"."profiles" from "service_role";

revoke update on table "public"."profiles" from "service_role";

revoke delete on table "public"."project_members" from "anon";

revoke insert on table "public"."project_members" from "anon";

revoke references on table "public"."project_members" from "anon";

revoke select on table "public"."project_members" from "anon";

revoke trigger on table "public"."project_members" from "anon";

revoke truncate on table "public"."project_members" from "anon";

revoke update on table "public"."project_members" from "anon";

revoke delete on table "public"."project_members" from "authenticated";

revoke insert on table "public"."project_members" from "authenticated";

revoke references on table "public"."project_members" from "authenticated";

revoke select on table "public"."project_members" from "authenticated";

revoke trigger on table "public"."project_members" from "authenticated";

revoke truncate on table "public"."project_members" from "authenticated";

revoke update on table "public"."project_members" from "authenticated";

revoke delete on table "public"."project_members" from "service_role";

revoke insert on table "public"."project_members" from "service_role";

revoke references on table "public"."project_members" from "service_role";

revoke select on table "public"."project_members" from "service_role";

revoke trigger on table "public"."project_members" from "service_role";

revoke truncate on table "public"."project_members" from "service_role";

revoke update on table "public"."project_members" from "service_role";

revoke delete on table "public"."projects" from "anon";

revoke insert on table "public"."projects" from "anon";

revoke references on table "public"."projects" from "anon";

revoke select on table "public"."projects" from "anon";

revoke trigger on table "public"."projects" from "anon";

revoke truncate on table "public"."projects" from "anon";

revoke update on table "public"."projects" from "anon";

revoke delete on table "public"."projects" from "authenticated";

revoke insert on table "public"."projects" from "authenticated";

revoke references on table "public"."projects" from "authenticated";

revoke select on table "public"."projects" from "authenticated";

revoke trigger on table "public"."projects" from "authenticated";

revoke truncate on table "public"."projects" from "authenticated";

revoke update on table "public"."projects" from "authenticated";

revoke delete on table "public"."projects" from "service_role";

revoke insert on table "public"."projects" from "service_role";

revoke references on table "public"."projects" from "service_role";

revoke select on table "public"."projects" from "service_role";

revoke trigger on table "public"."projects" from "service_role";

revoke truncate on table "public"."projects" from "service_role";

revoke update on table "public"."projects" from "service_role";

revoke delete on table "public"."remote_actors" from "anon";

revoke insert on table "public"."remote_actors" from "anon";

revoke references on table "public"."remote_actors" from "anon";

revoke select on table "public"."remote_actors" from "anon";

revoke trigger on table "public"."remote_actors" from "anon";

revoke truncate on table "public"."remote_actors" from "anon";

revoke update on table "public"."remote_actors" from "anon";

revoke delete on table "public"."remote_actors" from "authenticated";

revoke insert on table "public"."remote_actors" from "authenticated";

revoke references on table "public"."remote_actors" from "authenticated";

revoke select on table "public"."remote_actors" from "authenticated";

revoke trigger on table "public"."remote_actors" from "authenticated";

revoke truncate on table "public"."remote_actors" from "authenticated";

revoke update on table "public"."remote_actors" from "authenticated";

revoke delete on table "public"."remote_actors" from "service_role";

revoke insert on table "public"."remote_actors" from "service_role";

revoke references on table "public"."remote_actors" from "service_role";

revoke select on table "public"."remote_actors" from "service_role";

revoke trigger on table "public"."remote_actors" from "service_role";

revoke truncate on table "public"."remote_actors" from "service_role";

revoke update on table "public"."remote_actors" from "service_role";

revoke delete on table "public"."session_keys" from "anon";

revoke insert on table "public"."session_keys" from "anon";

revoke references on table "public"."session_keys" from "anon";

revoke select on table "public"."session_keys" from "anon";

revoke trigger on table "public"."session_keys" from "anon";

revoke truncate on table "public"."session_keys" from "anon";

revoke update on table "public"."session_keys" from "anon";

revoke delete on table "public"."session_keys" from "authenticated";

revoke insert on table "public"."session_keys" from "authenticated";

revoke references on table "public"."session_keys" from "authenticated";

revoke select on table "public"."session_keys" from "authenticated";

revoke trigger on table "public"."session_keys" from "authenticated";

revoke truncate on table "public"."session_keys" from "authenticated";

revoke update on table "public"."session_keys" from "authenticated";

revoke delete on table "public"."session_keys" from "service_role";

revoke insert on table "public"."session_keys" from "service_role";

revoke references on table "public"."session_keys" from "service_role";

revoke select on table "public"."session_keys" from "service_role";

revoke trigger on table "public"."session_keys" from "service_role";

revoke truncate on table "public"."session_keys" from "service_role";

revoke update on table "public"."session_keys" from "service_role";

revoke delete on table "public"."social_follows" from "anon";

revoke insert on table "public"."social_follows" from "anon";

revoke references on table "public"."social_follows" from "anon";

revoke select on table "public"."social_follows" from "anon";

revoke trigger on table "public"."social_follows" from "anon";

revoke truncate on table "public"."social_follows" from "anon";

revoke update on table "public"."social_follows" from "anon";

revoke delete on table "public"."social_follows" from "authenticated";

revoke insert on table "public"."social_follows" from "authenticated";

revoke references on table "public"."social_follows" from "authenticated";

revoke select on table "public"."social_follows" from "authenticated";

revoke trigger on table "public"."social_follows" from "authenticated";

revoke truncate on table "public"."social_follows" from "authenticated";

revoke update on table "public"."social_follows" from "authenticated";

revoke delete on table "public"."social_follows" from "service_role";

revoke insert on table "public"."social_follows" from "service_role";

revoke references on table "public"."social_follows" from "service_role";

revoke select on table "public"."social_follows" from "service_role";

revoke trigger on table "public"."social_follows" from "service_role";

revoke truncate on table "public"."social_follows" from "service_role";

revoke update on table "public"."social_follows" from "service_role";

revoke delete on table "public"."social_likes" from "anon";

revoke insert on table "public"."social_likes" from "anon";

revoke references on table "public"."social_likes" from "anon";

revoke select on table "public"."social_likes" from "anon";

revoke trigger on table "public"."social_likes" from "anon";

revoke truncate on table "public"."social_likes" from "anon";

revoke update on table "public"."social_likes" from "anon";

revoke delete on table "public"."social_likes" from "authenticated";

revoke insert on table "public"."social_likes" from "authenticated";

revoke references on table "public"."social_likes" from "authenticated";

revoke select on table "public"."social_likes" from "authenticated";

revoke trigger on table "public"."social_likes" from "authenticated";

revoke truncate on table "public"."social_likes" from "authenticated";

revoke update on table "public"."social_likes" from "authenticated";

revoke delete on table "public"."social_likes" from "service_role";

revoke insert on table "public"."social_likes" from "service_role";

revoke references on table "public"."social_likes" from "service_role";

revoke select on table "public"."social_likes" from "service_role";

revoke trigger on table "public"."social_likes" from "service_role";

revoke truncate on table "public"."social_likes" from "service_role";

revoke update on table "public"."social_likes" from "service_role";

revoke delete on table "public"."stripe_customers" from "anon";

revoke insert on table "public"."stripe_customers" from "anon";

revoke references on table "public"."stripe_customers" from "anon";

revoke select on table "public"."stripe_customers" from "anon";

revoke trigger on table "public"."stripe_customers" from "anon";

revoke truncate on table "public"."stripe_customers" from "anon";

revoke update on table "public"."stripe_customers" from "anon";

revoke delete on table "public"."stripe_customers" from "authenticated";

revoke insert on table "public"."stripe_customers" from "authenticated";

revoke references on table "public"."stripe_customers" from "authenticated";

revoke select on table "public"."stripe_customers" from "authenticated";

revoke trigger on table "public"."stripe_customers" from "authenticated";

revoke truncate on table "public"."stripe_customers" from "authenticated";

revoke update on table "public"."stripe_customers" from "authenticated";

revoke delete on table "public"."stripe_customers" from "service_role";

revoke insert on table "public"."stripe_customers" from "service_role";

revoke references on table "public"."stripe_customers" from "service_role";

revoke select on table "public"."stripe_customers" from "service_role";

revoke trigger on table "public"."stripe_customers" from "service_role";

revoke truncate on table "public"."stripe_customers" from "service_role";

revoke update on table "public"."stripe_customers" from "service_role";


  create policy "Public read Assets"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'Assets'::text));



  create policy "Service role full access Assets"
  on "storage"."objects"
  as permissive
  for all
  to service_role
using ((bucket_id = 'Assets'::text))
with check ((bucket_id = 'Assets'::text));



  create policy "Users delete own avatar in Assets"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'Assets'::text) AND ((storage.foldername(name))[1] = 'Avatars'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)));



  create policy "Users update own avatar in Assets"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'Assets'::text) AND ((storage.foldername(name))[1] = 'Avatars'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)));



  create policy "Users upload own avatar in Assets"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'Assets'::text) AND ((storage.foldername(name))[1] = 'Avatars'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)));



