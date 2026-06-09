# ZenFlow Yoga Studio — Full-Stack Database & Web Application

**Portfolio project by Braden Bourgeois** | [LinkedIn](#) | [Email](mailto:braden.bourg@gmail.com)

---

## About This Project

ZenFlow is a fully functional yoga studio management system built from the ground up — relational database design through to a complete customer-facing web application. It demonstrates the kind of end-to-end thinking employers look for: not just "can you write a query," but can you design a system that actually solves a real business problem.

The project covers customer registration, membership management, class scheduling, booking with real-time spot tracking, instructor portals, payroll automation, and purchase history — the same core workflows you'd find in production platforms like Mindbody or Club4Fitness.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | MySQL (relational schema, triggers, views, constraints) |
| Frontend | HTML5, CSS3 (custom design system), Vanilla JavaScript |
| Architecture | In-memory JS data store mirroring the SQL schema — production-ready for Node.js/Express backend integration |

---

## Database Design Highlights

The schema (`zenflow_yoga_schema.sql`) was designed with production principles in mind:

- **13 normalized tables** — `CUSTOMER`, `CLASS`, `CLASSPACKAGE`, `MEMBERSHIP`, `MEMBERSHIP_TYPE`, `INSTRUCTOR`, `TEACHES`, `REGISTER`, `SALE`, `INSTRUCTORPAYMENT`, `EMPLOYEE`, `WORK_SCHEDULE`, `PAYMENT`
- **5 automated triggers** that handle business logic at the database level:
  - Auto-deduct customer class credits on booking
  - Auto-restore credits and spots on cancellation
  - Auto-pay instructors when assigned to a class
  - Auto-calculate employee payroll when a shift is logged
  - Auto-update customer balance on package purchase
- **Indexes** on every foreign key and high-query column for performance
- **4 analytical views** — class schedule with instructor info, customer summaries, monthly revenue, class popularity rankings
- **Referential integrity** enforced via foreign keys, unique constraints, and check constraints throughout

This reflects real-world database engineering — not just tables with data in them, but a system where the database actively enforces business rules.

---

## Application Features

### Customer Side
- Account registration and login
- Browse and filter class schedule by difficulty level
- Book classes (with live spot availability tracking)
- Cancel bookings with automatic credit refund
- Purchase class packages and membership plans
- Personal dashboard — credit balance, upcoming classes, purchase history
- Profile management

### Instructor Side
- Dedicated instructor portal
- Schedule new classes with full details (date, time, capacity, room temp, difficulty)
- View class roster with student details
- Mark students as attended

### Business Logic (SQL Trigger Simulation)
Every action mirrors what the SQL triggers handle in the database:
- Booking a class → `-1 credit`, `-1 spot`
- Cancelling → `+1 credit`, `+1 spot`
- Purchasing a package → `+N credits` based on package
- Adding a shift → auto-calculates pay at the employee's hourly rate

---

## Why This Project Demonstrates Job Readiness

**Database design** is one of the most transferable skills in tech. A poorly designed schema causes performance issues, data integrity problems, and technical debt that haunts teams for years. This project shows I can design one correctly from the start — normalized, indexed, constrained, and automated.

**Full-stack thinking** — I didn't stop at the SQL file. I built the entire customer experience on top of it, making the data model tangible and testable. That kind of end-to-end ownership is what separates developers who understand systems from those who only know their slice of one.

**Real business domain** — membership apps, booking systems, and payroll are problems every company with a product or workforce has to solve. The patterns here (balance tracking, reservation systems, role-based portals) translate directly to SaaS products, internal tools, and consumer apps.

---

## Other Portfolio Projects

| Project | Skills Demonstrated |
|---|---|
| **Citi Bike Analysis** | SQL querying, data aggregation, trend analysis, ride pattern insights |
| **Meta Ads Performance** | Marketing analytics, KPI reporting, data visualization |
| **ZenFlow Yoga Studio** | Full database design, triggers, views, web application |

Each project was built to reflect real-world scenarios — not toy examples, but the kind of analysis and engineering work that shows up in actual job descriptions.

---

## What I'm Looking For

I'm actively seeking roles in:

- **Data Analytics / Business Intelligence** — SQL, dashboards, reporting, turning data into decisions
- **Junior / Associate Software Engineering** — Full-stack or backend-focused, database-heavy applications
- **Database Administration / Engineering** — Schema design, query optimization, data integrity

I'm a fast learner who builds things end to end, asks good questions, and cares about getting the details right. If your team values those things, I'd love to talk.

📧 braden.bourg@gmail.com

---

*Built with MySQL · HTML/CSS/JS · Designed for Braden Bourgeois's software & data engineering portfolio*
