# Wongherm Bakery — UX/UI brief (Week 2)

## Problem and opportunity

Customers who order from a small bakery need one place to browse current products, compare prices and options, place an order, and upload payment proof. Shop owners need a simple way to keep the catalog current and review incoming orders. Chatting across separate channels makes order details and payment evidence difficult to find later.

## Target users

- **Primary — bakery customers:** mobile-first users in Thailand who want to find and order cakes, cookies, brownies, and pastries without calling the shop.
- **Secondary — shop owner:** manages product names, prices, categories, photos, order status, and payment evidence.

## Main user flows

### Customer order flow

`Login / Register → Browse catalog → Search or filter → Product detail → Add to cart → Review cart → Confirm order → Upload payment proof → View order history / notifications`

### Owner catalog flow

`Login → Role check → Manage catalog → Add/edit/soft-delete product → Upload product photo → Review orders and payment evidence`

## Five mobile wireframes

### 1. Sign in / registration

```text
┌────────────────────────────┐
│       Wongherm Bakery      │
│ Email                      │
│ Password                   │
│ [ Sign in ]                │
│ Forgot password?           │
│ Create an account          │
└────────────────────────────┘
```

### 2. Product catalog

```text
┌────────────────────────────┐
│ Wongherm              Cart │
│ [ Search products       ]  │
│ [All] [Cake] [Cookie] ...  │
│ ┌──────────┐ ┌──────────┐  │
│ │ Product  │ │ Product  │  │
│ │ Name/฿   │ │ Name/฿   │  │
│ │   [+]    │ │   [+]    │  │
│ └──────────┘ └──────────┘  │
└────────────────────────────┘
```

### 3. Product detail and cart

```text
┌────────────────────────────┐
│ ‹ Product detail           │
│       Product photo        │
│ Product name       ฿ price│
│ Description                │
│ Options / variants         │
│ [ Add to cart ]            │
└────────────────────────────┘
```

### 4. Checkout and payment proof

```text
┌────────────────────────────┐
│ Confirm order              │
│ Items and quantities       │
│ Total                ฿... │
│ [ Confirm order ]          │
│ Payment proof              │
│ [ Choose image ]           │
│ [ Upload proof ]           │
└────────────────────────────┘
```

### 5. Order history and notifications

```text
┌────────────────────────────┐
│ Orders / Notifications     │
│ #104  Pending payment      │
│ #103  Confirmed            │
│ New order update      •    │
│ Payment proof received     │
└────────────────────────────┘
```

## Project and visual system

- Flutter mobile app; feature folders separate auth, products, cart/checkout, notifications, and owner product management.
- Theme lives in `lib/app/config/theme.dart`: bakery cream `#FFF8F0`, terracotta `#B4533F`, warm brown `#8D6E63`, and dark text `#3E2723`.
- Interactive storefront mockup: see the mobile design preview in the task conversation. This document keeps the five screen wireframes available with the source submission.

## Week 2 acceptance

- [x] Problem and target users documented.
- [x] Customer and owner flows documented.
- [x] Five mobile wireframes documented.
- [x] Flutter project structure and theme present.
- [ ] Obtain stakeholder/class review of the flows and wireframes.
