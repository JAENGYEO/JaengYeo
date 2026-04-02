CREATE TABLE sub_categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  main_category TEXT NOT NULL CHECK (main_category IN ('food', 'household')),
  name          TEXT NOT NULL,
  icon_name     TEXT,
  thumbnail_key TEXT,
  sort_order    INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER sub_categories_updated_at
  BEFORE UPDATE ON sub_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE sub_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_see_system_and_own"
  ON sub_categories FOR SELECT
  USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "users_manage_own"
  ON sub_categories FOR ALL
  USING (auth.uid() = user_id);

-- 식재료 기본 시드
INSERT INTO sub_categories (user_id, main_category, name, icon_name, thumbnail_key) VALUES
  (NULL, 'food', '채소',   'leaf',           'thumb_vegetable'),
  (NULL, 'food', '육류',   'fork.knife',     'thumb_meat'),
  (NULL, 'food', '해산물', 'fish',           'thumb_seafood'),
  (NULL, 'food', '유제품', 'cup.and.saucer', 'thumb_dairy'),
  (NULL, 'food', '음료',   'drop',           'thumb_beverage'),
  (NULL, 'food', '주류',   'wineglass',      'thumb_alcohol'),
  (NULL, 'food', '조미료', 'cart',           'thumb_seasoning'),
  (NULL, 'food', '향신료', 'leaf.fill',      'thumb_spice'),
  (NULL, 'food', '디저트', 'birthday.cake',  'thumb_dessert'),
  (NULL, 'food', '과자',   'star',           'thumb_snack'),
  (NULL, 'food', '곡류',   'bag',            'thumb_grain'),
  (NULL, 'food', '견과류', 'circle.fill',    'thumb_nut');
