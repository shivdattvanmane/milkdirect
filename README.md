# 🥛 MilkDirect — Farm-to-Door Fresh Milk Marketplace

Hyperlocal farm-to-door fresh milk marketplace built with **Flutter** (Android / iOS / Web) and backed by **Supabase**.

Features a **Role-Based Email & Password Authentication System** with separate entry points for **Customer**, **Supplier (Farmer / Milkman)**, and **Admin**, strict server-side & client-side role enforcement, verification workflows, live password strength meters, and a fresh Material 3 dairy theme.

Supported Languages: **English (EN)**, **हिंदी (Hindi - HI)**, and **मराठी (Marathi - MR)**.

---

## 🎨 1. Design System & Theme Tokens

The app follows a modern **Material 3 Milk & Farm Theme** (`lib/core/theme.dart`):

- **Scaffold Background**: Milk White (`#FDFCF8`)
- **Surfaces & Cards**: Cream (`#FFF7E6` & `#FFFBF2`), Pure White (`#FFFFFF`) with 16–20px rounded corners & subtle shadows
- **Primary Brand**: Pasture Green (`#2E7D32` / `#1B5E20`)
- **Secondary Brand**: Dairy Blue (`#1E6FD9`)
- **Accent**: Butter Warm Yellow (`#F6C453` / `#E5A823`)
- **Text & Typography**: Nunito & Poppins with Charcoal (`#1F2933`), Charcoal Light (`#52606D`), and Muted (`#7B8794`)
- **Buttons**: 54px tall pill/rounded buttons (`AppButton`, `FilledButton`, `OutlinedButton`)
- **Badges**: Rounded status pills with color indicators (`StatusBadge`)
- **Password Strength Meter**: Real-time 3-segment visual bar (Weak / Fair / Strong)

---

## 🔐 2. Role-Based Login & Registration Flows

### 1. Role Selection Screen (`lib/screens/auth/role_select_screen.dart`)
- **Customer Card**: Large illustrated card with Dairy Blue accents (`I am a Customer`).
- **Farmer / Milkman Card**: Large illustrated card with Pasture Green accents (`I am a Farmer / Milkman`).
- **Admin Login Link**: Discrete text link at the bottom (`Administrator Login →`).
- **Role Persistence & Instant Switching**: Remembers the chosen role in `SharedPreferences` (`last_role`) and skips straight to that login on next launch. Tapping "Change role" from ANY screen instantly clears the saved role and returns cleanly to the Role Selection screen.
- **Language Switcher**: Floating EN / HI / MR language selector.

### 2. Customer Portal
- **Login (`lib/screens/auth/customer_login_screen.dart`)**:
  - Email + Password authentication.
  - Show / hide password toggle.
  - "Forgot password?" &rarr; Opens password reset link screen.
  - "Register Here" &rarr; Opens customer registration screen.
  - Strict Role Check: If a registered Supplier tries to login, signs out and displays: *"This email is registered as a Supplier. Please use the Farmer / Milkman Login."*
- **Registration (`lib/screens/auth/customer_register_screen.dart`)**:
  - Compulsory Fields: Full name, Email (trimmed, lowercased), Contact Mobile (10 digits), Password (8+ chars, letters + numbers, live strength meter), Confirm Password.
  - Delivery Address: House / flat no., Society / street, Landmark, 6-digit PIN code, City / Village.
  - Preferred language selector & Terms of Service checkbox.
  - Email Confirmation: If email confirmation is enabled in Supabase, routes to `VerifyEmailScreen` with 30s resend timer. If confirmation is OFF, logs in immediately and routes to `CustomerHome`.

### 3. Supplier Portal (Farmer / Milkman)
- **Login (`lib/screens/auth/supplier_login_screen.dart`)**:
  - Email + Password authentication.
  - Show / hide password toggle.
  - "Forgot password?" &rarr; Opens password reset link screen.
  - "Register Here" &rarr; Opens supplier registration wizard.
  - Strict Role Check: If a registered Customer tries to login, signs out and displays: *"This email is registered as a Customer. Please use the Customer Login."*
- **Registration Wizard (`lib/screens/auth/supplier_register_wizard.dart`)**:
  - *Step 1 (Account & Type)*: Farmer (Own cattle) vs Milkman (Village sourced), Full Name, Farm / Business Name, Email, Contact Mobile, Password & Confirm Password.
  - *Step 2 (Location & Delivery)*: Village / Area, Farm PIN code, Service Delivery PIN codes (comma-separated).
  - *Step 3 (Payout & Operations)*: UPI ID for direct customer payouts, active delivery slots (Morning 5-8 AM, Morning 8-10 AM, Evening 5-8 PM), delivery charge, minimum order quantity.
  - *Step 4 (Quality & Verification)*: FSSAI license number (optional), pure milk & hygiene declaration, terms & privacy checkbox.
  - On submit: routes to `VerificationPendingScreen` (unverified suppliers can access their dashboard to manage milk listings, but remain hidden from customer discovery until admin approves).

### 4. Admin Portal (`lib/screens/auth/admin_login_screen.dart`)
- **Login**: Email + Password (Supabase email auth).
- **Security**: No admin sign-up UI in the app. Admins are created exclusively in Supabase database console (`mk_profiles.role = 'admin'`).
- **Strict Role Check**: Non-admin accounts are signed out immediately with *"Access Denied: This account does not have administrator privileges."*

---

## ⚙️ 3. Supabase Configuration Guide

To configure your Supabase project for Email + Password authentication:

1. **Authentication Providers**:
   - Go to **Supabase Dashboard &rarr; Authentication &rarr; Providers &rarr; Email**.
   - Ensure **Email Provider** is **Enabled**.
   - If you want users to verify email before logging in, keep **Confirm email** turned **ON**.
   - If you want immediate seamless login after registration, turn **Confirm email** **OFF**.
2. **Redirect URLs**:
   - Under **Authentication &rarr; URL Configuration**, add your web and mobile redirect URL (e.g., `http://localhost:3000` or `io.supabase.milkdirect://login-callback/`).
3. **Password Policy**:
   - Under **Authentication &rarr; Password Policy**, set Minimum length to **8 characters**.

---

## 🗄️ 4. Database Schema & Migration (`mk_` Tables)

All tables, functions, triggers, and RLS policies use the **`mk_`** prefix to safely coexist in shared Supabase projects (e.g. `queuekissan`):

- `mk_profiles`: User accounts with `role` (`customer`, `supplier`, `admin`), `is_blocked`, `language`, `phone` (email identifier), `alternate_phone` (contact mobile).
- `mk_supplier_profiles`: Farm name, type (`farmer`/`milkman`), `village`, `pincode`, `upi_id`, `delivery_slots`, `verification_status` (`pending`, `verified`, `rejected`), `rejection_reason`.
- `mk_products`: Milk listings (Cow, Buffalo, Other), price/L, fat/SNF%, processing, availability.
- `mk_addresses`: Multi-address book with default flag and coordinates.
- `mk_service_areas`: Delivery PIN codes served by each supplier.
- `mk_subscriptions`: Recurring deliveries (daily, alternate, custom weekdays).
- `mk_orders`: Daily delivery route orders with 1-tap delivery/missed status.
- `mk_reviews`: 1–5 star reviews and average rating recalculation trigger.
- `mk_complaints`: Customer dispute resolution tickets.

### Applying Migrations:
1. **Fresh Project**: Run `supabase/schema.sql` in the Supabase SQL Editor.
2. **Existing Project**: Run `supabase/migration.sql` to apply all updates and RLS policies.

---

## 👑 5. How to Create the First Admin User

Admin accounts cannot be registered from the mobile app:

### Step 1: Create Auth User in Supabase
1. In **Supabase Dashboard &rarr; Authentication &rarr; Users**, click **Add User &rarr; Create User**.
2. Enter the admin email (e.g., `admin@milkdirect.com`) and a strong password.
3. Check **Auto Confirm User**.
4. Copy the generated `User UID`.

### Step 2: Provision Admin Profile in SQL Editor
Run in the **Supabase SQL Editor**:
```sql
insert into mk_profiles (id, name, phone, role, language, is_blocked)
values (
  'PASTE_USER_UID_HERE',
  'Master Administrator',
  'admin@milkdirect.com',
  'admin',
  'en',
  false
)
on conflict (id) do update set role = 'admin';
```

---

## ✅ 6. Comprehensive Test Checklist

| # | Test Scenario | Steps | Expected Result |
|---|---|---|---|
| 1 | **Role Selection Launch** | Launch app on clean state | Displays 2 cards (Customer, Farmer/Milkman) and 1 bottom link (Admin). |
| 2 | **Role Persistence** | Select Customer, close & reopen app | Skips straight to Customer Login screen with a "Change role" button. |
| 3 | **Change Role Button (Unauthenticated)** | Click "Change role" on Customer / Supplier / Admin login | Clears `selectedRole` from `SharedPreferences` and instantly returns to Role Selection screen. |
| 4 | **Change Role Button (Authenticated)** | Click "Sign Out" from Customer Profile / Supplier Home / Admin Home | Signs out of Supabase, clears saved role, and returns cleanly to Role Selection screen. |
| 5 | **Customer Registration** | Open Customer Register &rarr; Fill name, email, phone, address, PIN &rarr; Submit | Registers via `signUpWithPassword`, creates profile & address records, routes to `CustomerHome` (or `VerifyEmailScreen` if confirmation ON). |
| 6 | **Password Strength Meter** | Type passwords of varying complexity | Shows Weak (red, <8 chars/no numbers), Fair (orange, mixed), Strong (green, 8+ alphanumeric). |
| 7 | **Password Mismatch** | Type different confirm password | Shows inline error: *"Passwords do not match"*. |
| 8 | **Duplicate Email Registration** | Register with an already existing email | Shows inline error: *"This email is already registered. Please sign in."* |
| 9 | **Supplier Registration Wizard** | Complete 4 steps (Type, Location, UPI & Slots, Quality Declaration) | Registers supplier, creates profile & service area PIN records, routes to `VerificationPendingScreen`. |
| 10 | **Wrong-Role Enforcement (Supplier &rarr; Customer)** | On Customer Login, enter email registered as Supplier | Signs out immediately and displays: *"This email is registered as a Supplier. Please use the Farmer / Milkman Login."* |
| 11 | **Wrong-Role Enforcement (Customer &rarr; Supplier)** | On Supplier Login, enter email registered as Customer | Signs out immediately and displays: *"This email is registered as a Customer. Please use the Customer Login."* |
| 12 | **Admin Login Flow** | Enter `admin@milkdirect.com` + password | Validates `role == 'admin'`, routes to Admin Dashboard. |
| 13 | **Admin Rejection** | Attempt Admin sign in with non-admin email | Signs out immediately and shows: *"Access Denied: This account does not have administrator privileges."* |
| 14 | **Forgot Password Flow** | Click "Forgot Password" &rarr; Enter email &rarr; Submit | Sends password reset email via Supabase Auth and starts 30s resend cooldown. |
| 15 | **Blocked Account Handling** | Set `is_blocked = true` on any profile in Supabase | Login attempt is blocked with: *"Your account has been blocked. Please contact support."* |
| 16 | **Supplier Verification Flow** | Admin approves pending supplier in Admin Dashboard | Supplier status becomes `verified`; milk listings become visible to all nearby customers. |
| 17 | **Language Switching** | Toggle EN / HI / MR on any screen | Instant UI translation across login screens, registration forms, and error banners. |

---

## 🚀 7. How to Run

1. **Install dependencies**:
```powershell
flutter pub get
```

2. **Run on Chrome (Web)**:
```powershell
flutter run -d chrome
```

3. **Build Android Release APK**:
```powershell
flutter build apk --release
```
