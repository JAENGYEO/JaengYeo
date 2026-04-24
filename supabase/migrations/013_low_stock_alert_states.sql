-- 재고 부족 피보나치 알림 추적 테이블
-- send_count 인덱스별 대기 일수: [1, 2, 3, 5, 8]
-- send_count = 5 도달 시 알림 종료
-- 재고가 threshold 초과 회복 시 레코드 삭제 (Edge Function에서 처리)
CREATE TABLE low_stock_alert_states (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL,
  item_id            UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  first_low_stock_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_sent_at       TIMESTAMPTZ,
  send_count         INTEGER NOT NULL DEFAULT 0,
  UNIQUE(user_id, item_id)
);

ALTER TABLE low_stock_alert_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_only"
  ON low_stock_alert_states
  USING (true)
  WITH CHECK (true);
