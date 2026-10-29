-- In-app customer ↔ shop-owner chat. Apply in the Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists chat_conversations_customer_updated_idx
  on public.chat_conversations (customer_id, updated_at desc);
create index if not exists chat_messages_conversation_created_idx
  on public.chat_messages (conversation_id, created_at);

create or replace function public.is_chat_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and lower(role) = 'owner'
  );
$$;

revoke all on function public.is_chat_admin() from public;
grant execute on function public.is_chat_admin() to authenticated;

create or replace function public.touch_chat_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.chat_conversations
  set updated_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists chat_message_touches_conversation on public.chat_messages;
create trigger chat_message_touches_conversation
after insert on public.chat_messages
for each row execute function public.touch_chat_conversation();

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "chat participants read conversations" on public.chat_conversations;
create policy "chat participants read conversations"
on public.chat_conversations for select to authenticated
using (customer_id = auth.uid() or public.is_chat_admin());

drop policy if exists "customers create own conversations" on public.chat_conversations;
create policy "customers create own conversations"
on public.chat_conversations for insert to authenticated
with check (customer_id = auth.uid() and not public.is_chat_admin());

drop policy if exists "participants read messages" on public.chat_messages;
create policy "participants read messages"
on public.chat_messages for select to authenticated
using (
  exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.customer_id = auth.uid() or public.is_chat_admin())
  )
);

drop policy if exists "participants send messages as themselves" on public.chat_messages;
create policy "participants send messages as themselves"
on public.chat_messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and c.status = 'open'
      and (c.customer_id = auth.uid() or public.is_chat_admin())
  )
);

grant select, insert on public.chat_conversations to authenticated;
grant select, insert on public.chat_messages to authenticated;

-- Supabase Realtime is needed for live incoming messages and inbox updates.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_conversations'
  ) then
    alter publication supabase_realtime add table public.chat_conversations;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;
