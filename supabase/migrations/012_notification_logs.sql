CREATE TABLE notification_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL,
  item_id     UUID REFERENCES items(id) ON DELETE SET NULL,
  type        TEXT NOT NULL CHECK (type IN ('expiry_evening', 'expiry_noon', 'low_stock')),
  sent_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  apns_status TEXT CHECK (apns_status IN ('success', 'failed', 'invalid_token'))
);

ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_only"
  ON notification_logs
  USING (true)
  WITH CHECK (true);
