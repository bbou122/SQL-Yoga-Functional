# ZenFlow Yoga Studio — Data Dictionary

**Author:** Braden Bourgeois  
**Database:** MySQL  
**Last Updated:** June 2026

A complete reference for every table, column, constraint, and relationship in the ZenFlow schema.

---

## Table of Contents

1. [CUSTOMER](#customer)
2. [MEMBERSHIP_TYPE](#membership_type)
3. [MEMBERSHIP](#membership)
4. [CLASSPACKAGE](#classpackage)
5. [INSTRUCTOR](#instructor)
6. [CLASS](#class)
7. [TEACHES](#teaches)
8. [INSTRUCTORPAYMENT](#instructorpayment)
9. [SALE](#sale)
10. [REGISTER](#register)
11. [EMPLOYEE](#employee)
12. [WORK_SCHEDULE](#work_schedule)
13. [PAYMENT](#payment)
14. [Entity Relationship Summary](#entity-relationship-summary)

---

## CUSTOMER

Stores every person who has registered an account with the studio, whether or not they hold an active membership.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `customerID` | INT | PK, AUTO_INCREMENT | Unique identifier for each customer |
| `fname` | VARCHAR(50) | NOT NULL | Customer's first name |
| `lname` | VARCHAR(50) | NOT NULL | Customer's last name |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Login email. Enforced unique across all customers |
| `phone` | VARCHAR(20) | nullable | Contact phone number |
| `gender` | CHAR(1) | CHECK (M/F/O) | Optional gender indicator: M, F, or O (Other) |
| `dob` | DATE | nullable | Date of birth. Used for age verification and birthday promotions |
| `joindate` | DATE | NOT NULL, DEFAULT CURRENT_DATE | The date the customer created their account |
| `classbalance` | INT | NOT NULL, DEFAULT 0 | Number of class credits remaining. Decremented on booking, incremented on purchase or cancellation. Managed by triggers |
| `password_hash` | VARCHAR(255) | nullable | Reserved for future backend authentication integration |

**Indexes:** `email` (unique), implicit PK index on `customerID`

**Key relationships:** One customer can have many SALE records, many REGISTER records, and one active MEMBERSHIP.

---

## MEMBERSHIP_TYPE

A lookup/reference table defining the available membership plans. Separating plan definitions from customer subscriptions allows plan pricing to be updated without affecting historical membership records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `membershipTypeID` | INT | PK, AUTO_INCREMENT | Unique identifier for each plan |
| `typeName` | VARCHAR(100) | NOT NULL | Display name (e.g., "Standard", "Unlimited") |
| `typeDescription` | VARCHAR(255) | nullable | Short marketing description of the plan |
| `monthlyPrice` | DECIMAL(10,2) | NOT NULL | Monthly cost in USD |
| `classesPerMonth` | INT | nullable | Number of classes included. NULL indicates unlimited |

**Seeded plans:**

| ID | Name | Price | Classes |
|---|---|---|---|
| 2 | Basic | $39/mo | 4 |
| 3 | Standard | $65/mo | 8 |
| 4 | Unlimited | $99/mo | Unlimited |
| 5 | Annual Unlimited | $79/mo | Unlimited |

---

## MEMBERSHIP

Tracks which customers are subscribed to which plan, and when. A customer can have multiple membership records over time (e.g., upgraded, cancelled, reactivated), but only one should be ACTIVE at a time.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `membershipID` | INT | PK, AUTO_INCREMENT | Unique identifier for the subscription record |
| `customerID` | INT | FK → CUSTOMER, NOT NULL | The subscribing customer |
| `membershipTypeID` | INT | FK → MEMBERSHIP_TYPE, NOT NULL | Which plan the customer is on |
| `startDate` | DATE | NOT NULL | When the subscription began |
| `endDate` | DATE | nullable | When the subscription ends or ended. NULL = open-ended (ongoing) |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'ACTIVE', CHECK (ACTIVE/CANCELLED/EXPIRED) | Current state of the subscription |

**Indexes:** `customerID`

---

## CLASSPACKAGE

Defines the punch-card style class packages customers can purchase. Each package adds a fixed number of credits to the customer's `classbalance`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `classpackageID` | INT | PK, AUTO_INCREMENT | Unique identifier for the package |
| `classpackagedesc` | VARCHAR(255) | NOT NULL | Display name (e.g., "10-Class Pass") |
| `classpackageprice` | DECIMAL(10,2) | NOT NULL | Purchase price in USD |
| `numClasses` | INT | NOT NULL | Number of class credits the package provides |

**Seeded packages:**

| ID | Description | Price | Credits |
|---|---|---|---|
| 1 | Single Class | $18.00 | 1 |
| 2 | 5-Class Pass | $80.00 | 5 |
| 3 | 10-Class Pass | $140.00 | 10 |
| 4 | 20-Class Pass | $240.00 | 20 |

---

## INSTRUCTOR

Stores the yoga studio's teaching staff. Instructors are separate from EMPLOYEE — they are compensated per class via INSTRUCTORPAYMENT, not hourly via WORK_SCHEDULE.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `instructorID` | INT | PK, AUTO_INCREMENT | Unique identifier for the instructor |
| `instfname` | VARCHAR(50) | NOT NULL | First name |
| `instlname` | VARCHAR(50) | NOT NULL | Last name |
| `instphone` | VARCHAR(20) | nullable | Contact phone |
| `instdob` | DATE | nullable | Date of birth |
| `inststartdate` | DATE | nullable | Date the instructor joined the studio |
| `instgender` | CHAR(1) | CHECK (M/F/O) | Optional gender indicator |
| `bio` | TEXT | nullable | Public-facing biography shown on the website |
| `specialty` | VARCHAR(100) | nullable | Comma-separated list of yoga styles the instructor specializes in |

---

## CLASS

Each row represents a single scheduled class session. Classes are linked to an instructor and hold information about timing, capacity, and room conditions.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `classID` | INT | PK, AUTO_INCREMENT | Unique identifier for the class session |
| `classname` | VARCHAR(100) | NOT NULL | Name of the class (e.g., "Vinyasa Flow") |
| `classtemp` | DECIMAL(5,2) | nullable | Room temperature in °F. Relevant for hot yoga variants |
| `startTime` | TIME | NOT NULL | Scheduled start time |
| `endTime` | TIME | NOT NULL | Scheduled end time |
| `classDate` | DATE | NOT NULL | Date the class takes place |
| `spotsAvailable` | INT | NOT NULL, DEFAULT 20, CHECK ≥ 0 | Current open spots. Decremented by trigger on REGISTER insert, incremented on cancellation |
| `spotsTotal` | INT | NOT NULL, DEFAULT 20 | Maximum capacity for the class. Never changes after creation |
| `instructorID` | INT | FK → INSTRUCTOR, SET NULL on delete | The assigned instructor. NULL if not yet assigned |
| `difficulty` | VARCHAR(20) | CHECK (Beginner/Intermediate/Advanced/All Levels) | Skill level label shown to customers |
| `description` | TEXT | nullable | Class description shown on the schedule |

**Indexes:** `classDate`, `instructorID`

---

## TEACHES

A junction table linking instructors to the classes they teach. Inserting a row here automatically fires the `trg_PayInstructorAfterTeach` trigger, creating an INSTRUCTORPAYMENT record.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `teachesID` | INT | PK, AUTO_INCREMENT | Unique identifier |
| `instructorID` | INT | FK → INSTRUCTOR, CASCADE delete | The instructor |
| `classID` | INT | FK → CLASS, CASCADE delete | The class being taught |

**Constraints:** UNIQUE on `(instructorID, classID)` — an instructor can only be linked to a class once.

---

## INSTRUCTORPAYMENT

Records per-class compensation for instructors. Rows are created automatically by the `trg_PayInstructorAfterTeach` trigger when a TEACHES record is inserted.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `paymentID` | INT | PK, AUTO_INCREMENT | Unique identifier |
| `instructorID` | INT | FK → INSTRUCTOR | The instructor being paid |
| `classID` | INT | FK → CLASS | The class the payment is for |
| `paymentAmount` | DECIMAL(10,2) | NOT NULL | Amount paid (currently fixed at $50.00 per class) |
| `paymentDate` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Date the payment was recorded |

**Indexes:** `instructorID`

---

## SALE

Records every class package purchase made by a customer. Inserting a SALE row triggers `trg_UpdateClassBalanceAfterSale`, which adds the corresponding number of credits to the customer's balance.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `saleID` | INT | PK, AUTO_INCREMENT | Unique identifier for the transaction |
| `customerID` | INT | FK → CUSTOMER, NOT NULL | The purchasing customer |
| `classpackageID` | INT | FK → CLASSPACKAGE, NOT NULL | The package purchased |
| `saleDate` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Date of the transaction |
| `paymentType` | VARCHAR(50) | nullable | Payment method (Credit Card, Cash, PayPal, etc.) |
| `amountPaid` | DECIMAL(10,2) | nullable | Actual dollar amount collected |

**Indexes:** `customerID`

---

## REGISTER

Records customer sign-ups for individual class sessions. This is the central booking table. Inserting a row triggers `trg_UpdateBalanceAndSpotsAfterRegister`; updating `status` to CANCELLED triggers `trg_RestoreOnCancellation`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `registerID` | INT | PK, AUTO_INCREMENT | Unique identifier for the booking |
| `customerID` | INT | FK → CUSTOMER, NOT NULL | The customer who booked |
| `classID` | INT | FK → CLASS, NOT NULL | The class being booked |
| `registerDate` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Date the booking was made |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'REGISTERED', CHECK (REGISTERED/CANCELLED/ATTENDED) | Current booking state. Supports soft-delete via CANCELLED rather than deleting rows |

**Constraints:** UNIQUE on `(customerID, classID)` — a customer cannot book the same class twice.  
**Indexes:** `customerID`, `classID`

---

## EMPLOYEE

Non-instructor staff such as desk employees, cleaners, and managers. Compensated hourly via WORK_SCHEDULE and PAYMENT.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `employeeID` | INT | PK, AUTO_INCREMENT | Unique identifier |
| `empfname` | VARCHAR(50) | NOT NULL | First name |
| `emplname` | VARCHAR(50) | NOT NULL | Last name |
| `role` | VARCHAR(50) | nullable | Job title (Desk Employee, Cleaner, Manager, etc.) |
| `phone` | VARCHAR(20) | nullable | Contact phone |
| `hourlyRate` | DECIMAL(10,2) | NOT NULL, DEFAULT 15.00 | Hourly pay rate used by the payroll trigger |

---

## WORK_SCHEDULE

Records every shift worked by an employee. Inserting a row triggers `trg_CalculateEmployeePayment`, which auto-creates a PAYMENT record based on hours worked and the employee's hourly rate.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `scheduleID` | INT | PK, AUTO_INCREMENT | Unique identifier for the shift |
| `employeeID` | INT | FK → EMPLOYEE, NOT NULL | The employee working the shift |
| `workDate` | DATE | NOT NULL | Calendar date of the shift |
| `startTime` | TIME | NOT NULL | Shift start time |
| `endTime` | TIME | NOT NULL | Shift end time |

**Indexes:** `employeeID`

---

## PAYMENT

Records payroll disbursements to employees. Created automatically by the `trg_CalculateEmployeePayment` trigger when a WORK_SCHEDULE record is inserted.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `paymentID` | INT | PK, AUTO_INCREMENT | Unique identifier |
| `employeeID` | INT | FK → EMPLOYEE, NOT NULL | The employee being paid |
| `paymentAmount` | DECIMAL(10,2) | NOT NULL | Calculated as hours worked × hourly rate |
| `paymentDate` | DATE | NOT NULL, DEFAULT CURRENT_DATE | Date the payment was recorded |

---

## Entity Relationship Summary

```
CUSTOMER ──< SALE >── CLASSPACKAGE
CUSTOMER ──< MEMBERSHIP >── MEMBERSHIP_TYPE
CUSTOMER ──< REGISTER >── CLASS
CLASS >── INSTRUCTOR
CLASS ──< TEACHES >── INSTRUCTOR
INSTRUCTOR ──< INSTRUCTORPAYMENT
EMPLOYEE ──< WORK_SCHEDULE
EMPLOYEE ──< PAYMENT
```

**Cardinality key:** `──<` = one-to-many, `>──<` = many-to-many (resolved through junction table)

### Trigger Map

| Trigger | Fires On | Effect |
|---|---|---|
| `trg_UpdateClassBalanceAfterSale` | INSERT on SALE | Adds package credits to customer's `classbalance` |
| `trg_UpdateBalanceAndSpotsAfterRegister` | INSERT on REGISTER | Deducts 1 credit from customer, deducts 1 from class `spotsAvailable`. Raises error if balance = 0 or class is full |
| `trg_RestoreOnCancellation` | UPDATE on REGISTER (status → CANCELLED) | Restores 1 credit to customer and 1 spot to class |
| `trg_PayInstructorAfterTeach` | INSERT on TEACHES | Creates an INSTRUCTORPAYMENT record ($50.00 per class) |
| `trg_CalculateEmployeePayment` | INSERT on WORK_SCHEDULE | Creates a PAYMENT record: hours × employee hourly rate |
