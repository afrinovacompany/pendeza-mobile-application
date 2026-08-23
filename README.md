# Pendeza Booking App

Beauty & salon booking platform for Tanzania.

## Stack
- Flutter (Client / Owner / Admin)
- Firebase Auth, Firestore, Cloud Functions
- Briq SMS (OTP + booking notifications)
- Google Sign-In / Apple Sign-In (iOS handoff)

## Roles
- **Client** — discover, book, appointments
- **Owner** — salon profile, schedule, services, walk-ins
- **Admin** — approve salons, users, promotions, bookings overview

## Current release notes (1.6.0)
- Auth + Briq OTP stable
- Client polish (Home, Discovery, Profile, Booking)
- Owner go-live checklist + walk-in
- Admin salon approval + Bookings overview
- Payments temporarily disabled for store submission
- SMS booking confirmations enabled

## Android build
```bash
flutter pub get
flutter build appbundle --release