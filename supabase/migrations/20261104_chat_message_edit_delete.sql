-- เพิ่มเวลาแก้ไขและจำกัดการแก้/ลบข้อความให้เจ้าของข้อความในห้องที่ยังเปิดอยู่
alter table public.chat_messages
  add column if not exists edited_at timestamptz;

drop policy if exists "participants edit own messages"
  on public.chat_messages;
create policy "participants edit own messages"
on public.chat_messages for update to authenticated
using (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.chat_conversations as conversation
    where conversation.id = conversation_id
      and conversation.status = 'open'
      and (
        conversation.customer_id = auth.uid()
        or public.is_chat_admin()
      )
  )
)
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.chat_conversations as conversation
    where conversation.id = conversation_id
      and conversation.status = 'open'
      and (
        conversation.customer_id = auth.uid()
        or public.is_chat_admin()
      )
  )
);

drop policy if exists "participants delete own messages"
  on public.chat_messages;
create policy "participants delete own messages"
on public.chat_messages for delete to authenticated
using (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.chat_conversations as conversation
    where conversation.id = conversation_id
      and conversation.status = 'open'
      and (
        conversation.customer_id = auth.uid()
        or public.is_chat_admin()
      )
  )
);

revoke update on public.chat_messages from authenticated;
grant update (body, edited_at) on public.chat_messages to authenticated;
grant delete on public.chat_messages to authenticated;
