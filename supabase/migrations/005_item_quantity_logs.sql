CREATE TABLE item_quantity_logs (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id   UUID REFERENCES items(id) ON DELETE SET NULL,
  item_name TEXT NOT NULL,   -- 아이템 삭제 후에도 패턴 분석 가능하도록 복사
  delta     INTEGER NOT NULL,
  reason    TEXT CHECK (reason IN ('purchase', 'consume', 'adjust', 'delete')),
  logged_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE item_quantity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_logs"
  ON item_quantity_logs FOR ALL
  USING (auth.uid() = user_id);
