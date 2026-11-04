-- Create in-app notifications for new bakery orders, submitted slips, and
-- owner updates. Requires the existing notifications and user_roles tables.

create or replace function public.notify_new_order()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.notifications (user_id, title, message, is_read)
  values (
    new.user_id,
    'รับคำสั่งซื้อแล้ว',
    format('ร้านได้รับคำสั่งซื้อ #%s แล้ว', new.id),
    false
  );

  insert into public.notifications (user_id, title, message, is_read)
  select roles.user_id,
         'มีคำสั่งซื้อใหม่',
         format('มีคำสั่งซื้อ #%s เข้ามาใหม่', new.id),
         false
  from public.user_roles as roles
  where lower(roles.role) = 'owner';

  return new;
end;
$$;

drop trigger if exists orders_create_notifications on public.orders;
create trigger orders_create_notifications
after insert on public.orders
for each row execute function public.notify_new_order();

create or replace function public.notify_payment_proof_submitted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.notifications (user_id, title, message, is_read)
  select roles.user_id,
         'มีหลักฐานการชำระเงินใหม่',
         format('ลูกค้าส่งสลิปสำหรับคำสั่งซื้อ #%s', new.order_id),
         false
  from public.user_roles as roles
  where lower(roles.role) = 'owner';

  return new;
end;
$$;

drop trigger if exists payment_proofs_create_notifications
  on public.payment_proofs;
create trigger payment_proofs_create_notifications
after insert on public.payment_proofs
for each row execute function public.notify_payment_proof_submitted();

create or replace function public.notify_order_status_changed()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  details text := '';
begin
  if new.status is distinct from old.status then
    details := details || format('สถานะคำสั่งซื้อ: %s', new.status);
  end if;

  if new.payment_status is distinct from old.payment_status then
    if details <> '' then details := details || ' • '; end if;
    details := details || format('สถานะชำระเงิน: %s', new.payment_status);
  end if;

  if details <> '' then
    insert into public.notifications (user_id, title, message, is_read)
    values (
      new.user_id,
      format('อัปเดตคำสั่งซื้อ #%s', new.id),
      details,
      false
    );
  end if;

  return new;
end;
$$;

drop trigger if exists orders_update_notifications on public.orders;
create trigger orders_update_notifications
after update of status, payment_status on public.orders
for each row execute function public.notify_order_status_changed();

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;

notify pgrst, 'reload schema';
