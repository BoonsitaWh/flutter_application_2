create or replace function public.review_payment_for_order(
  p_order_id bigint,
  p_approved boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_proof_id public.payment_proofs.id%type;
begin

  -- Prevent NULL approval value
  if p_approved is null then
    raise exception 'Approval status cannot be null';
  end if;

  -- Check shop owner permission
  if not exists (
    select 1
    from public.user_roles
    where user_id = (select auth.uid())
      and lower(role) = 'owner'
  ) then
    raise exception 'Only a shop owner can review payment proofs';
  end if;

  -- Find latest pending payment proof
  select id
    into v_proof_id
  from public.payment_proofs
  where order_id = p_order_id
    and status = 'pending'
  order by created_at desc
  limit 1
  for update;

  if v_proof_id is null then
    raise exception 'No pending payment proof exists for this order';
  end if;

  -- Update payment proof status
  update public.payment_proofs
  set status = case
    when p_approved then 'approved'
    else 'rejected'
  end
  where id = v_proof_id;

  -- Update order payment status
  update public.orders
  set payment_status = case
    when p_approved then 'paid'
    else 'unpaid'
  end
  where id = p_order_id;

  if not found then
    raise exception 'Order not found';
  end if;

end;
$$;

revoke all on function
  public.review_payment_for_order(bigint, boolean)
  from public, anon;

grant execute on function
  public.review_payment_for_order(bigint, boolean)
  to authenticated;
