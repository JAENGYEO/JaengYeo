CREATE TABLE items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 기본 정보
  name            TEXT NOT NULL,
  quantity        INTEGER NOT NULL DEFAULT 1,
  quantity_unit   TEXT,

  -- 카테고리
  main_category   TEXT NOT NULL CHECK (main_category IN ('food', 'household')),
  mid_category_id UUID REFERENCES mid_categories(id),
  sub_category_id UUID REFERENCES sub_categories(id),

  -- 선택 필드
  purchase_date   TIMESTAMPTZ,
  expiry_date     TIMESTAMPTZ,
  price           INTEGER,
  location_memo   TEXT,
  memo            TEXT,
  image_url       TEXT,

  -- 상태
  is_classified                     BOOLEAN NOT NULL DEFAULT true,
  is_favorite                       BOOLEAN NOT NULL DEFAULT false,
  is_low_stock_notification_enabled BOOLEAN NOT NULL DEFAULT false,
  low_stock_threshold               INTEGER NOT NULL DEFAULT 1,

  -- 동기화
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ          -- 소프트 삭제
);

CREATE TRIGGER items_updated_at
  BEFORE UPDATE ON items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_items"
  ON items FOR ALL
  USING (auth.uid() = user_id AND deleted_at IS NULL);
