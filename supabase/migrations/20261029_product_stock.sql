-- Adds the inventory field used by the product editor and storefront.
-- Run this in Supabase SQL Editor before deploying the updated app.
alter table public.products
  add column if not exists stock_quantity integer not null default 0;

alter table public.products
  drop constraint if exists products_stock_quantity_nonnegative;

alter table public.products
  add constraint products_stock_quantity_nonnegative
  check (stock_quantity >= 0);
