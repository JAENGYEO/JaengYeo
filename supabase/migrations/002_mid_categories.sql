CREATE TABLE mid_categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                -- NULL이면 시스템 기본값, NOT NULL이면 사용자 커스텀
  main_category TEXT NOT NULL CHECK (main_category IN ('food', 'household')),
  name          TEXT NOT NULL,
  icon_name     TEXT,
  sort_order    INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER mid_categories_updated_at
  BEFORE UPDATE ON mid_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE mid_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_see_system_and_own"
  ON mid_categories FOR SELECT
  USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "users_manage_own"
  ON mid_categories FOR ALL
  USING (auth.uid() = user_id);

-- 기본 시드
INSERT INTO mid_categories (user_id, main_category, name, icon_name) VALUES
  (NULL, 'food',      '냉장고',  'refrigerator'),
  (NULL, 'food',      '실온',    'house'),
  (NULL, 'household', '주방',    'fork.knife'),
  (NULL, 'household', '거실',    'sofa'),
  (NULL, 'household', '화장실',  'shower'),
  (NULL, 'household', '창고',    'archivebox');
