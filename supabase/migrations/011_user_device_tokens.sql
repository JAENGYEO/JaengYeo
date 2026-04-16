-- user_id는 auth.users FK 없음 → devUserId(고정 UUID)도 등록 가능
-- Sign in with Apple 구현 후 REFERENCES auth.users(id) 추가 예정
CREATE TABLE user_device_tokens (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL,
  device_token TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, device_token)
);

CREATE TRIGGER user_device_tokens_updated_at
  BEFORE UPDATE ON user_device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE user_device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_only"
  ON user_device_tokens
  USING (true)
  WITH CHECK (true);
