# Apple App Privacy answers (App Store Connect -> App Privacy)

Answer "Yes, we collect data from this app", then declare exactly these.

## Contact Info
- Email Address        -> App Functionality, Account Management. Linked to user. Not used for tracking.
- Name                 -> App Functionality, Account Management. Linked to user. Not used for tracking.

## Identifiers
- User ID              -> App Functionality. Linked to user. Not used for tracking.

## Usage Data
- Product Interaction  -> Analytics, App Functionality. Linked to user. Not used for tracking.
  (workouts completed, videos viewed, streaks)

## Purchases
- Purchase History     -> App Functionality. Linked to user. Not used for tracking.
  (membership status and program purchases; card details are handled by Stripe
   and never reach MD Fit servers)

## Diagnostics
- Crash Data           -> App Functionality. Not linked to user.
- Performance Data     -> App Functionality. Not linked to user.

## Declare NOT collected
Health & Fitness, Location, Financial Info (card numbers), Contacts, Browsing
History, Search History, Sensitive Info, Photos, Audio, Gameplay Content.

## Tracking
"Do you or your third-party partners use data for tracking?" -> NO.
No ad networks, no cross-app tracking, no IDFA. Do not add App Tracking
Transparency.
