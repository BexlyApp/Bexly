-- Align bexly.plan_quotas with the canonical 3-tier pricing in
-- docs/PREMIUM_PLAN.md after Bexly dropped per-model selection in the UI.
--
-- Final shape (4 rows total):
--   free  | standard |  60
--   go    | standard | 240
--   plus  | standard | 600   (Premium UI label)
--   pro   | standard | 600   (DOS.AI Pro user opening Bexly gets max tier)
--
-- premium/flagship tiers are dropped — Bexly client only requests model
-- "dos-ai" which maps to 'standard' tier on the gateway. If Bexly ever
-- introduces a higher-cost model path (e.g. flagship OCR), reintroduce
-- those rows in a new migration.

-- 1. Drop dormant tier rows
DELETE FROM bexly.plan_quotas
  WHERE model_tier IN ('premium', 'flagship');

-- 2. Add the missing Go tier (was absent — Go users fell back to Free quota)
INSERT INTO bexly.plan_quotas (plan, model_tier, monthly_limit)
  VALUES ('go', 'standard', 240)
ON CONFLICT (plan, model_tier)
  DO UPDATE SET monthly_limit = EXCLUDED.monthly_limit;

-- 3. Align Plus (Premium UI) to canonical 600
UPDATE bexly.plan_quotas SET monthly_limit = 600
  WHERE plan = 'plus' AND model_tier = 'standard';

-- 4. Pro users (paying for higher tier on another DOS product) get the
--    same Bexly cap as Plus — never less than what they'd get on Premium.
UPDATE bexly.plan_quotas SET monthly_limit = 600
  WHERE plan = 'pro' AND model_tier = 'standard';
