# local_transport_info

## Supabase seed (stops/routes/fare)

- Run the SQL in [supabase_seed.sql](supabase_seed.sql) in Supabase **SQL Editor**.
- This project expects tables named `stops`, `routes`, and `fares`.
- For backward compatibility, the app will also read/write `fare` if your project still uses the older singular table.
- If you have RLS enabled, also apply the included SELECT policies at the bottom of the SQL file.

## Admin login (modify fares)

This app uses Supabase Auth for admin login and an `admins` table for access control.

1) Create a Supabase Auth user (email + password).
2) Create the `admins` table (see the commented SQL near the bottom of [supabase_seed.sql](supabase_seed.sql)).
3) Insert the admin user:

```
insert into public.admins (email)
values ('admin@gmail.com');

-- OR (if you prefer linking by UUID too)
insert into public.admins (user_id, email)
values ('<AUTH_USER_UUID>', 'admin@example.com');
```

4) If RLS is enabled, add the `admins` policies and (optionally) the `admins manage fares` policy from the same SQL file.

Now tap the Admin icon in the app bar, sign in, and you can modify fare costs.

## Run (Supabase credentials)

This app reads Supabase credentials from Dart defines.

Recommended (uses the checked-in [supabase.env.json](supabase.env.json) file):

- Edge:
	- `flutter run -d edge --dart-define-from-file=supabase.env.json`
- Chrome:
	- `flutter run -d chrome --dart-define-from-file=supabase.env.json`
- Windows:
	- `flutter run -d windows --dart-define-from-file=supabase.env.json`

Admin mode:

- `flutter run -d edge --dart-define-from-file=supabase.env.json --dart-define=IS_ADMIN=true`

If you prefer passing values directly:

- `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
