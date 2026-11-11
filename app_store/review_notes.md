# App Review Information — paste into App Store Connect

## Sign-in required
Yes.

Demo account (fill these in before submitting):
- Email:    reviewer@mymdfit.com
- Password: __________

This account has an active membership so the reviewer sees the full paid
experience without making a purchase.

## Notes for the reviewer

MD Fit is the companion app for Dr. Jared Caban's movement-medicine practice in
Sarasota, Florida. It is an educational movement-exercise app. It does not
diagnose, treat, or claim to treat any condition, and the Pain Tool shows a
disclaimer plus red-flag guidance directing users to a professional.

Native functionality beyond web content:
- Push notifications for visit reminders, messages from the practice, and
  streak nudges (APNs, registered in AppDelegate)
- Sign in with Apple
- Home-screen quick actions: Start a workout, Pain Tool, My progress,
  Message Dr. Jared
- Native checkout sheet (ASWebAuthenticationSession) so Apple Pay is available
- Calendar integration via EventKit for scheduled workouts and classes
- Offline handling with cached state

Memberships: memberships are digital subscriptions and are purchased through an
external link that opens in Safari, under the external purchase link allowance
for the United States storefront. Bookings for in-person clinic visits are
physical services and are paid the same way. No digital content is unlocked
inside the app without the member being signed in to their account.

Account deletion: members can delete their account and all associated data from
Profile -> Account -> Delete account. [VERIFY THIS EXISTS BEFORE SUBMITTING]

Health data: the app does not read or write Apple Health data in this version.
