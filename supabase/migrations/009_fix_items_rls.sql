-- items RLS 정책 수정
-- 기존 FOR ALL 정책은 소프트 삭제(UPDATE deleted_at) 시 WITH CHECK에서 막히는 문제가 있음
-- SELECT/INSERT/UPDATE/DELETE를 분리하여 소프트 삭제가 정상 동작하도록 수정

DROP POLICY IF EXISTS "users_own_items" ON items;

-- SELECT: 삭제되지 않은 본인 아이템만 조회
CREATE POLICY "users_select_own_items"
  ON items FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);

-- INSERT: 본인 user_id로만 삽입 가능
CREATE POLICY "users_insert_own_items"
  ON items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: 삭제되지 않은 본인 아이템만 수정 가능 (소프트 삭제 포함)
-- WITH CHECK에서 deleted_at 조건을 제거하여 소프트 삭제 허용
CREATE POLICY "users_update_own_items"
  ON items FOR UPDATE
  USING (auth.uid() = user_id AND deleted_at IS NULL)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: 물리 삭제는 사용하지 않으나 방어적으로 추가
CREATE POLICY "users_delete_own_items"
  ON items FOR DELETE
  USING (auth.uid() = user_id);
