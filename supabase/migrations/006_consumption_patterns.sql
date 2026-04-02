CREATE TABLE consumption_patterns (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_name                 TEXT NOT NULL,
  avg_days_between_purchase NUMERIC,
  avg_consumption_rate      NUMERIC,
  last_calculated_at        TIMESTAMPTZ,
  UNIQUE(user_id, item_name)
);

ALTER TABLE consumption_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_patterns"
  ON consumption_patterns FOR ALL
  USING (auth.uid() = user_id);
