-- Phase 2 완료(Sign in with Apple 연동) 후 이 마이그레이션을 제거하거나 롤백한다
INSERT INTO auth.users (
  id, email, encrypted_password, created_at, updated_at, role
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'dev@test.com', '', now(), now(), 'authenticated'
) ON CONFLICT (id) DO NOTHING;
