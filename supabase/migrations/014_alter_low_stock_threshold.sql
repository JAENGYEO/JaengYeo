-- low_stock_threshold를 nullable로 변경, 기본값 제거
ALTER TABLE items
  ALTER COLUMN low_stock_threshold DROP NOT NULL,
  ALTER COLUMN low_stock_threshold SET DEFAULT NULL;

-- 알림 비활성 상품은 null로 업데이트
UPDATE items
SET low_stock_threshold = NULL
WHERE is_low_stock_notification_enabled = false;
