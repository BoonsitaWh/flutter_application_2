-- Atomic pre-order checkout. Apply after the base orders/products schema and
-- product stock migration are present in Supabase.
alter table public.products
  add column if not exists stock_quantity integer not null default 0;

do $$
declare
  variant_id_type text;
begin
  select format_type(attribute.atttypid, attribute.atttypmod)
    into variant_id_type
  from pg_attribute as attribute
  where attribute.attrelid = 'public.product_variants'::regclass
    and attribute.attname = 'id'
    and not attribute.attisdropped;

  if variant_id_type is null then
    raise exception 'product_variants.id column was not found';
  end if;

  execute format(
    'alter table public.order_items add column if not exists variant_id %s',
    variant_id_type
  );
end;
$$;

create or replace function public.create_order_with_stock(p_items jsonb)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_item record;
  v_product_id public.products.id%type;
  v_variant_id public.product_variants.id%type;
  v_order_id public.orders.id%type;
  v_stock integer;
  v_required integer;
  v_base_price numeric;
  v_additional_price numeric;
  v_unit_price numeric;
  v_total numeric := 0;
begin
  if v_user_id is null then
    raise exception 'กรุณาเข้าสู่ระบบก่อนสั่งซื้อ';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'ไม่มีสินค้าในคำสั่งซื้อ';
  end if;

  if jsonb_array_length(p_items) > 50 then
    raise exception 'คำสั่งซื้อมีสินค้าเกินจำนวนที่กำหนด';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as item(product_id bigint, variant_id bigint, quantity integer)
    where item.product_id is null or item.product_id <= 0
       or item.quantity is null or item.quantity <= 0
  ) then
    raise exception 'ข้อมูลสินค้าในตะกร้าไม่ถูกต้อง';
  end if;

  -- Lock products in a stable order to avoid overselling and reduce deadlocks.
  for v_item in
    select distinct item.product_id
    from jsonb_to_recordset(p_items) as item(product_id bigint, variant_id bigint, quantity integer)
    order by item.product_id
  loop
    v_product_id := v_item.product_id;
    select product.stock_quantity
      into v_stock
    from public.products as product
    where product.id = v_product_id
      and product.is_active = true
    for update;

    if not found then
      raise exception 'ไม่พบสินค้าหรือสินค้าถูกปิดขาย';
    end if;

    select coalesce(sum(item.quantity), 0)::integer
      into v_required
    from jsonb_to_recordset(p_items) as item(product_id bigint, variant_id bigint, quantity integer)
    where item.product_id = v_item.product_id;

    if v_stock < v_required then
      raise exception 'สินค้าเหลือไม่พอ กรุณาตรวจสอบตะกร้าอีกครั้ง';
    end if;
  end loop;

  -- Recalculate every line from cloud prices; do not trust the client total.
  for v_item in
    select item.product_id, item.variant_id, item.quantity
    from jsonb_to_recordset(p_items) as item(product_id bigint, variant_id bigint, quantity integer)
  loop
    v_product_id := v_item.product_id;
    v_variant_id := v_item.variant_id;

    select product.base_price
      into v_base_price
    from public.products as product
    where product.id = v_product_id
      and product.is_active = true;

    if not found then
      raise exception 'ไม่พบสินค้าหรือสินค้าถูกปิดขาย';
    end if;

    v_additional_price := 0;
    if v_variant_id is not null then
      select variant.additional_price
        into v_additional_price
      from public.product_variants as variant
      where variant.id = v_variant_id
        and variant.product_id = v_product_id;

      if not found then
        raise exception 'ตัวเลือกสินค้าไม่ถูกต้อง';
      end if;
    end if;

    v_unit_price := v_base_price + v_additional_price;
    v_total := v_total + (v_unit_price * v_item.quantity);
  end loop;

  insert into public.orders (user_id, total_amount, status, payment_status)
  values (v_user_id, v_total, 'pending', 'unpaid')
  returning id into v_order_id;

  for v_item in
    select item.product_id, item.variant_id, item.quantity
    from jsonb_to_recordset(p_items) as item(product_id bigint, variant_id bigint, quantity integer)
  loop
    v_product_id := v_item.product_id;
    v_variant_id := v_item.variant_id;

    select product.base_price + coalesce(variant.additional_price, 0)
      into v_unit_price
    from public.products as product
    left join public.product_variants as variant
      on variant.id = v_variant_id
     and variant.product_id = product.id
    where product.id = v_product_id;

    insert into public.order_items (
      order_id, product_id, variant_id, quantity, unit_price, subtotal
    ) values (
      v_order_id, v_product_id, v_variant_id, v_item.quantity,
      v_unit_price, v_unit_price * v_item.quantity
    );
  end loop;

  update public.products as product
  set stock_quantity = product.stock_quantity - requested.quantity
  from (
    select item.product_id, sum(item.quantity)::integer as quantity
    from jsonb_to_recordset(p_items) as item(product_id bigint, variant_id bigint, quantity integer)
    group by item.product_id
  ) as requested
  where product.id = requested.product_id;

  return v_order_id::bigint;
end;
$$;

revoke all on function public.create_order_with_stock(jsonb) from public, anon;
grant execute on function public.create_order_with_stock(jsonb) to authenticated;

notify pgrst, 'reload schema';
