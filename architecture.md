# ZenFlow Yoga Studio — Architecture & Design Decisions

**Author:** Braden Bourgeois  
**Project Type:** Portfolio — SQL Database Design + Web Application

---

## Overview

ZenFlow is a full studio management system built across two layers: a relational MySQL database that enforces all core business rules, and a JavaScript web application that exposes those rules to customers and staff. This document explains the design decisions behind the schema — what was built, why, and what tradeoffs were considered.

---

## Database Design

### Normalization Strategy

The schema follows **Third Normal Form (3NF)** throughout:

- No repeating groups (all multi-value data is broken into separate tables)
- Every non-key attribute depends on the whole primary key, not a part of it
- No transitive dependencies — attributes only depend on the primary key, not on other non-key columns

The most important example of this is the split between `MEMBERSHIP_TYPE` and `MEMBERSHIP`.

**Why not just put `planName` and `planPrice` directly on the MEMBERSHIP table?**

If you store plan details directly on each membership row, updating a plan's price requires updating potentially hundreds of rows — and you lose the ability to distinguish "this customer was on the $65 plan" from "this customer is on the $65 plan that we've since repriced to $75." Separating the plan definition into `MEMBERSHIP_TYPE` means pricing history is preserved automatically and plan updates are a single-row change.

---

### Instructor vs. Employee

A deliberate decision was made to keep `INSTRUCTOR` and `EMPLOYEE` as **separate tables** rather than using a single `STAFF` table with a role column.

**Reason:** Their compensation models are fundamentally different.

- Employees (desk staff, cleaners) are paid hourly. Their pay flows through `WORK_SCHEDULE` → `PAYMENT` via a trigger that calculates `hours × hourlyRate`.
- Instructors are paid per class. Their pay flows through `TEACHES` → `INSTRUCTORPAYMENT` via a trigger that fires a flat per-class rate.

Merging them into one table would require nullable columns for whichever compensation model doesn't apply, and the triggers would need conditional logic to determine which payment path to take. Keeping them separate makes both models clean, readable, and independently extensible. If the studio later adds contractor rates or tiered instructor pay, only the `INSTRUCTOR`/`INSTRUCTORPAYMENT` tables need to change.

---

### The TEACHES Junction Table

`CLASS` already has an `instructorID` foreign key — so why does `TEACHES` exist?

**`CLASS.instructorID`** answers: *"Who is the primary instructor for this class?"* It's used for display (the schedule shows the instructor's name) and for filtering.

**`TEACHES`** answers: *"Which instructor gets paid for this class?"* It's what triggers the payment record. In the future, a class could have a substitute instructor, a co-instructor, or a guest teacher — `TEACHES` handles all of those cases without touching the `CLASS` table.

This is the difference between a display relationship and a business-process relationship.

---

### Soft Deletes on REGISTER

Bookings are never hard-deleted. When a customer cancels, the row's `status` column is updated to `CANCELLED` instead of the row being removed.

**Why this matters:**

1. **Audit trail** — you can always answer "did this customer ever book this class?" Hard deletes destroy that history permanently.
2. **Trigger correctness** — the `trg_RestoreOnCancellation` trigger fires on UPDATE, not DELETE. This keeps all balance restoration logic inside the database layer, not the application layer.
3. **Analytics** — cancellation rate analysis (see `analysis_queries.sql` Query 9) requires knowing about cancelled bookings. You can't calculate a cancellation rate if the data is gone.

The same philosophy applies to `MEMBERSHIP.status` — memberships are marked CANCELLED or EXPIRED rather than deleted.

---

### Business Logic in Triggers vs. Application Code

All five triggers enforce rules that *must be true at all times*, regardless of which application writes to the database:

| Rule | Where Enforced | Why Here |
|---|---|---|
| Class credits deducted on booking | Trigger on REGISTER | Cannot be bypassed by any client |
| Credits restored on cancellation | Trigger on REGISTER update | Ensures consistency even on direct DB writes |
| Spots decremented on booking | Trigger on REGISTER | Prevents overbooking at the DB level |
| Instructor paid on class assignment | Trigger on TEACHES | Payment is automatic — no manual step to miss |
| Employee paid on shift entry | Trigger on WORK_SCHEDULE | Eliminates human error in payroll calculation |

**The alternative** — handling all of this in application code — means every future API endpoint, admin tool, or data pipeline that writes to these tables must remember to also update balances, spots, and payments. That's a maintenance problem waiting to become a bug. Triggers make the rules database-native.

---

### Constraints as Documentation

Every `CHECK`, `UNIQUE`, and `FOREIGN KEY` constraint in this schema does double duty: it enforces data integrity *and* documents an assumption about the data.

For example:
- `CHECK (status IN ('REGISTERED','CANCELLED','ATTENDED'))` tells anyone reading the schema exactly what states a booking can be in — no guessing, no looking at application code.
- `UNIQUE (customerID, classID)` on REGISTER documents that a customer cannot book the same class twice — the constraint *is* the business rule.
- `FOREIGN KEY (instructorID) ... ON DELETE SET NULL` on CLASS documents that deleting an instructor shouldn't cascade-delete all their past classes — just clear the reference.

---

## Web Application Design

### In-Memory Data Store

The HTML application uses a JavaScript object (`DB`) as an in-memory database that mirrors the SQL schema exactly — same table names, same column names, same relationships. Every action on the frontend (booking, purchasing, cancelling) runs the same logic the SQL triggers would run in production.

This architecture was chosen deliberately for the portfolio context:

- The site runs entirely in the browser with no server required — easy to demo, easy to share
- The data model is validated end-to-end even without a backend
- Swapping to a real backend is additive, not a rewrite — the frontend logic stays the same, the JS database calls become API calls

### Role Separation

The application has three distinct user contexts with different capabilities:

| Role | Access | Portal |
|---|---|---|
| **Guest** | Browse schedule, view packages | Public pages only |
| **Customer** | Book classes, purchase packages, manage profile, view dashboard | Member dashboard |
| **Instructor** | Schedule classes, view rosters, mark attendance | Instructor portal |

This maps directly to how a production RBAC (role-based access control) system would work. In a backend deployment, these roles would correspond to JWT claims or session-based permissions.

---

## What a Production Version Would Add

This project is intentionally scoped as a portfolio piece, but the path to production is straightforward:

| Feature | What's Needed |
|---|---|
| Real auth | Node.js/Express backend, bcrypt password hashing, JWT sessions |
| Real payments | Stripe Checkout + webhook to trigger SALE insert |
| Data persistence | Connect frontend to REST API backed by the MySQL schema |
| Admin dashboard | New role + portal for studio managers to manage all data |
| Email notifications | SendGrid or similar on booking confirmation and class reminders |
| Recurring billing | Stripe Subscriptions for monthly membership auto-renewal |

The database schema as designed supports all of these without structural changes.

---

## File Structure

```
zenflow-yoga/
├── README.md                        ← Project overview and portfolio context
├── zenflow_yoga_schema.sql          ← Full schema: tables, triggers, views, constraints
├── zenflow_yoga.html                ← Complete web application (open in browser)
├── seed/
│   └── seed_data.sql                ← Sample data only, separate from schema
├── queries/
│   └── analysis_queries.sql         ← 10+ business analysis queries
└── docs/
    ├── data_dictionary.md           ← Column-level documentation for every table
    └── architecture.md              ← This file — design decisions and rationale
```
