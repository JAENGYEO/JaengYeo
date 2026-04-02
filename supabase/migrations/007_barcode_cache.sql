CREATE TABLE barcode_cache (
  barcode       TEXT PRIMARY KEY,
  product_name  TEXT,
  manufacturer  TEXT,
  raw_response  JSONB,
  cached_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  hit_count     INTEGER DEFAULT 1
);
-- RLS 없음 — 전체 사용자 공유 캐시
