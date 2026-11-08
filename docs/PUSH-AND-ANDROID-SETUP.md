# Push notifications + Android: what Dr. Jared has to do once

The code for notifications (iPhone and Android) and the Android app is written. These are the account steps only
the account owner can do. Each one is a few minutes.

## 1. iPhone notifications (Apple)

1. **Turn on push for the App ID.** developer.apple.com → Certificates, Identifiers & Profiles → Identifiers →
   `com.mdfitsrq.MDfit` → tick **Push Notifications** → Save. (Until this is ticked, the next Codemagic iOS build
   fails at signing with "doesn't support the Push Notifications capability".)
2. **Make an APNs key.** Same site → Keys → **+** → name it `MD Fit push` → tick **Apple Push Notifications service
   (APNs)** → Continue → Register → **Download** the `.p8` file (Apple shows it once) and note the **Key ID**.
3. **Give the key to the server.** Railway → the backend service → Variables:
   - `APNS_KEY` = the whole contents of the `.p8` file (open it in TextEdit, copy everything)
   - `APNS_KEY_ID` = the Key ID from step 2
   - `APNS_TEAM_ID` = `N6HQNTVSZB` (already the default; set it only if the team changes)
   Railway redeploys by itself. Never paste the key anywhere else.
4. Start a new iOS build in Codemagic. Install it from TestFlight, open the app signed in, allow notifications when asked.

## 2. Android app (Google)

1. **Google Play Console** (play.google.com/console, one-time $25 fee, use the MD Fit company account, not a personal
   one) → Create app → name `MD Fit`, package name `com.mdfitsrq.mdfit`.
2. **Signing key.** Codemagic → Teams → Code signing identities → Android keystores → **Generate** → reference name
   `mdfit_keystore`. Download a copy and keep it with the passwords somewhere safe: every future update must be
   signed with this same key.
3. Start the **Android → Play (internal testing)** workflow in Codemagic. It produces `app-release.aab` (for Play)
   and `app-release.apk` (installs directly on any Android phone for testing: open the artifact link on the phone).
4. Upload the `.aab` in Play Console → Testing → Internal testing → Create release. Add testers by email.
   (Later, Codemagic can upload automatically: uncomment the `google_play` block in `codemagic.yaml` after adding a
   Play service account under Codemagic → Teams → Integrations.)

## 3. Android notifications (Firebase)

1. console.firebase.google.com → Add project `MD Fit` (analytics off is fine) → Add app → **Android** → package
   `com.mdfitsrq.mdfit` → download **google-services.json**.
2. Put that file at `android/app/google-services.json` in the `mymdfitapp` repo and push (it is not secret; the app
   builds without it, but push stays off until it's there).
3. Firebase → Project settings → **Service accounts** → **Generate new private key** → a JSON file downloads.
   Railway → backend Variables → `FCM_SERVICE_ACCOUNT` = the whole contents of that JSON. Never share it elsewhere.

## 4. Backend code

The server side is on branch `push-notifications` in the `mdfit-backend` repo (rebased on the latest main; 123 tests
pass). Merge it into `main` and Railway deploys it. Nothing sends until the variables in steps 1 and 3 exist, so it is
safe to merge first.

## What members get

| Event | Who | Opens |
|---|---|---|
| Booked a visit (from their account) | member | Home → upcoming visits |
| Day before a visit, 6 PM; and 1 hour before | member | Home |
| Video-visit link added or changed | member | Home |
| Dr. Jared scheduled a video consult / sent a booking link | member | Home |
| Dr. Jared replied, or sent a group message | member | Messages |
| Plan updated / program added | member | Programs |
| 1-on-1 scheduled | member | Home |
| Payment failed | member | Premium |
| Streak at risk (7 PM, local, no server needed) | member | Home |
| New booking, cancellation, class booking, new message, lead, 1-on-1 or membership request, new member, review, intake complete | Dr. Jared (Admin signed in on the app) | Admin |

Notifications never include health details: visit type, time, who wrote. Each one plays the app's chime and
vibrates; achievements (XP, badges, gems, daily goal) have their own sounds inside the app.
