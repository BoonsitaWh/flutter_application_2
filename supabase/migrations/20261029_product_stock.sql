-- เพิ่มช่องสต๊อกโดยไม่กำหนดสินค้าเดิมเป็นหมดสต๊อก
alter table public.products
  add column if not exists stock_quantity integer;

-- ลบ constraint เดิมถ้ามี
alter table public.products
  drop constraint if exists products_stock_quantity_nonnegative;

-- อนุญาต NULL แต่ห้ามจำนวนสต๊อกติดลบ
alter table public.products
  add constraint products_stock_quantity_nonnegative
  check (stock_quantity is null or stock_quantity >= 0);
