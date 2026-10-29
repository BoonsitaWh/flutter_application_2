# Wongherm Bakery — Data model (Week 3)

This is the schema contract inferred from the current Flutter queries and writes. Compare it with the deployed Supabase database before applying changes. This document does not migrate or alter a live project.

## Entity relationship

```text
auth.users ──1:1── user_roles
auth.users ──1:N── orders ──1:N── order_items ──N:1── products
products ──1:N── product_variants
orders ──1:N── payment_proofs
auth.users ──1:N── notifications
auth.users ──1:N── chat_conversations ──1:N── chat_messages
```

## Tables and fields used by the app

| Table | Fields used | Relationship / purpose |
|---|---|---|
| `user_roles` | `user_id`, `role` | One role per auth user; `customer` or `owner` |
| `products` | `id`, `name`, `description`, `base_price`, `category`, `image_urls`, `stock_quantity`, `is_active`, `created_at` | Public catalog; owner create/update; soft-delete via `is_active=false` |
| `product_variants` | `id`, `product_id`, `variant_name`, `additional_price` | Options belonging to one product |
| `orders` | `id`, `user_id`, `total_amount`, `status`, `payment_status`, `created_at` | Customer order; owner order-review UI is future work |
| `order_items` | `id`, `order_id`, `product_id`, `quantity`, `unit_price`, `subtotal` | Immutable purchase snapshot for an order |
| `payment_proofs` | `id`, `order_id`, `user_id`, `image_path`, `status`, `created_at` | Uploaded payment evidence and review status |
| `notifications` | `id`, `user_id`, `title`, `message`, `is_read`, `created_at` | In-app messages; only the owner of the row marks it read |
| `chat_conversations` | `id`, `customer_id`, `status`, `created_at`, `updated_at` | One support conversation per customer; visible to that customer and owners |
| `chat_messages` | `id`, `conversation_id`, `sender_id`, `body`, `created_at` | Realtime messages; sender must be an authenticated participant |

## Storage buckets

- `product-images`: public read URLs are stored in `products.image_urls`; writes should require owner role.
- `payment-proofs`: private bucket; app stores the object path in `payment_proofs.image_path` and creates a short-lived signed URL for viewing.

## Security and integrity requirements

- Enable RLS on all public tables. Customers can read active products, create/read only their own orders and proofs, and read/update only their own notification read state.
- Owners can manage products and review orders/proofs. Assign `owner` from a trusted admin context; never allow a user to self-assign owner role.
- `order_items` must only reference products and orders the authenticated customer can access. Keep `unit_price` and `subtotal` as order-time snapshots.
- Use foreign keys and indexes for `user_id`, `order_id`, `product_id`, `category`, and `created_at` query paths.
- Never ship the Supabase service-role key in the app. The app uses the public anon key and depends on RLS for authorization.

## Local and cloud data flow

```text
UI → ProductService → Supabase products/product_variants
                    ↘ SQLite cached_products
Network read succeeds: refresh the local product cache.
Network read fails: show the last cached active catalog, if available.
Successful owner create/update/soft-delete: reflect the cloud result in SQLite.
Orders, payment proofs, roles, notifications, and chat remain cloud-only.
```

## Chat setup

Apply [`../supabase/migrations/20261020_chat.sql`](../supabase/migrations/20261020_chat.sql) in the Supabase SQL Editor. The migration creates the conversation/message tables, indexes, owner-role helper, RLS policies, updated-at trigger, and Realtime publication entries. Verify that the deployed `user_roles` table has `user_id` and `role` columns matching the existing app before applying. The app does not apply this migration automatically and has not changed the live Supabase project.

## Inventory rollout

Apply [`../supabase/migrations/20261029_product_stock.sql`](../supabase/migrations/20261029_product_stock.sql) before using the updated product editor. The app displays and validates the manually maintained available quantity, but checkout does not yet reserve or decrement stock atomically. Add a server-side transactional checkout before treating the quantity as authoritative under concurrent orders.

## Remaining product requirements

- Coupons/discounts are not implemented. Add coupon validation and price calculation on the server before showing a discounted checkout total.
- Payment uses customer-uploaded proof with a pending review state. It is not an automatic payment gateway or verified payment confirmation.
- Product variants are currently free-form labels with an optional additional price in the data model; the create form currently stores labels with zero additional price. Structured color/size combinations and per-variant inventory remain future work.
- The owner dashboard currently links to catalog and chat, but does not provide order/payment review metrics or fulfillment controls.
- Chat currently supports text messages only; image upload is not implemented.

The SQLite cache currently supports offline catalog reads. It is **not** an offline write queue: create/update/delete still require Supabase and the local cache is updated after a successful cloud mutation. This limitation should be stated in the Week 3 presentation if the rubric expects offline write synchronization.

## Cache schema

`cached_products(id TEXT PRIMARY KEY, category TEXT, is_active INTEGER, payload TEXT, cached_at TEXT)`

The `payload` column stores the product and nested variants JSON returned by Supabase. Catalog data is public and non-sensitive; do not cache orders, profile data, or payment evidence in this table.
