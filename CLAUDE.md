# MD Fit Online — Claude Code Context

## Identity & Business

**MD Fit Online** — Movement-education platform connecting Dr. Jared Caban's Sarasota clinical practice to an online video library, pain-pattern tool, workout generator, structured training programs, and personalized dashboard.

- **Owner**: Dr. Jared Caban
- **Location**: 3214 Clark Road, Sarasota, FL 34231
- **Phone**: 941.313.0562
- **Website**: mdfitsrq.com
- **Current Stack**: WordPress (audit before reuse)

> **NOT a diagnostic service** — educational content only.

---

## Core Platform Modules

| # | Module | Description |
|---|--------|-------------|
| 1 | **Pain Tool** | Free visual body-region/referred-pain selector → approved exercise videos |
| 2 | **Video Library** | Searchable tagged library, limited free daily views, unlimited premium |
| 3 | **Workout Generator** | Rule-based random workout builder (see screenshot) |
| 4 | **Custom Workouts** | Build-your-own workouts |
| 5 | **Programs** | Purchasable + membership-included structured training |
| 6 | **Dashboard** | Next workout, progress, resume state |
| 7 | **Billing** | Subscriptions, purchases, entitlements |
| 8 | **Admin CMS** | Content management |
| 9 | **Video Review** | Paid upload/review workflow (post-beta) |
| 10 | **Events/Calendar** | Group classes, workshops, in-person sessions → user calendars |
| 11 | **Management Portal** | Admin dashboard for Dr. Jared (see below) |

---

## Management Portal (Admin)

Web-based admin for Dr. Jared to run the business:

### Events & Calendar
- Create events (group classes, workshops, mobility sessions, in-person)
- Set capacity, pricing, location (clinic or virtual)
- Recurring events (weekly mobility class, etc.)
- Events sync to enrolled users' iOS Calendar via EventKit
- Push notifications for upcoming events
- Waitlist management

### Content Management
- Upload/manage exercise videos
- Create/edit programs (weeks, days, exercises)
- Manage Pain Tool mappings (region → exercises)
- Approve/reject video review submissions

### User Management
- View all users, subscriptions, entitlements
- Grant/revoke access
- View progress, completion rates
- Send announcements/notifications

### Billing & Analytics
- Revenue dashboard
- Subscription metrics (MRR, churn)
- Active users, video views, workout completions
- Program enrollment stats

### Ticketing (Future - Lightning Pass style)
- Create ticketed events (seminars, workshops)
- QR code check-in
- Capacity management
- Payment processing

---

## Workout Generator (from screenshot)

**Inputs:**
- **Goal/Type**: Upper Body, Lower Body, Full Body, Cardio, Foundational
- **Location**: Home, Outdoor, Gym, Minimal, Hotel, Office
- **Difficulty**: Beginner, Intermediate, Advanced, Elite
- **Length**: 15-60 min slider
- **Exercises per Round**: 2, 4, 6, 8, 10, 12
- **Rounds**: 1, 2, 3, 4, 5
- **Rest Between Exercises**: slider
- **Rest Between Rounds**: slider

**Optional Add-ons:**
- Warm-up
- Cool Down
- Abs
- Core Specifics

**Calendar Integration:**
- Calendar view alongside generator
- Tap date → schedule generated workout
- See existing workouts, events, programs on calendar
- Syncs to iOS Calendar via EventKit

**Output:** Workout Summary with exercise list, sets, reps, rest times

**Actions:** Generate Workout, Randomize Settings, Schedule to Calendar

---

## Shared Movement Engine — Data Model

```swift
// Core entities from spec
Exercise
VideoAsset
BodyRegion
PainPattern
ExerciseTag
Program
ProgramWeek
ProgramDay
Workout
WorkoutExercise      // prescription lives here, not on Exercise
Enrollment
Completion
User
Entitlement
Purchase
ReviewSubmission
```

### Video Metadata
- Exercise name
- Permanent ID
- Video filename/URL (naming: `REGION_CATEGORY_MOVEMENT_SUBTYPE.mp4`)
- Body region
- Muscle emphasis
- Category
- Equipment
- Level
- Cues
- Tempo
- Default prescription
- Modifications
- Exclusions
- Safety notes
- Program associations
- Approval status

### Prescription Model
Support on `WorkoutExercise` (not just Exercise):
- Reps, Sets, Tempo
- Duration, Distance
- Intensity, Load
- Coaching cues
- Modification
- Stop rules
- Rest
- Free-form activity days

> Rehab: 3-10 slow pain-limited reps
> Conditioning: sets of 20

---

## Pain Tool Flow

```
Front/Back body tap
    ↓
Select region (shoulder, lower back, knee, etc.)
    ↓
Show illustrated referred-pain patterns
    ↓
Display approved suggested movement videos
    ↓
Educational disclaimer + red-flag guidance + "See professional" option
```

**No medical diagnosis claims.**

---

## Programs & Training Inventory

| Program | Details |
|---------|---------|
| **Golf** | Rotational power, cable swing, lateral med-ball release, Golfer Switch Row, reactive jump-lunge |
| **Pickleball** | Sport movement, tied to 51-item filming checklist |
| **Running** | Beginner + Advanced 8-week; mechanics: midfoot landing, glutes, trunk rotation, shoulders down, slight forward lean |
| **Ski** | Beginner/Intermediate/Advanced concepts, 8-week advanced sequence, Mon/Wed/Fri prescriptions |
| **Rehab** | Shoulder-release, plantar fascia, lower-back/SI |
| **General** | Mobility, strength, weight-loss, HIIT |

---

## Business Model

| Tier | Price | Access |
|------|-------|--------|
| **Free** | $0 | Pain tool + limited daily video views |
| **Premium** | $20/mo (proposed) | Unlimited video + programs |
| **90-Day Micro Momentum** | $9/mo × 3 | Intro offer |
| **Beta Grandfathered** | $9.95/mo lifetime | After beta |
| **Program Purchase** | varies | One-time program access |
| **Video Review** | paid | Movement analysis submission |

Support: coupons, lifetime price cohorts, subscriptions, cancellations, refunds, entitlements.

---

## Beta Launch

- 50-100 controlled testers
- Test: Pain tool, video playback, tagging/search, generator, custom workouts, account/login, program resume, payments/access, mobile responsive, bug submission, analytics
- Establish test scripts + written acceptance criteria

---

## App Navigation (iOS)

Based on screenshot sidebar:
1. **Dashboard** — Home, next workout
2. **My Programs** — Enrolled programs
3. **Workout Generator** — Rule-based builder
4. **Video Library** — Browse/search all videos
5. **Pain Tool** — Body region selector
6. **Progress Tracking** — Completions, stats
7. **Resources** — Educational content
8. **My Profile** — Account, settings, billing

---

## Brand Identity

### Colors (from screenshot)
| Token | Value | Usage |
|-------|-------|-------|
| `--primary` | #0066CC | Blue headers, buttons |
| `--accent` | #FF7A00 | Orange CTAs |
| `--dark` | #1A1A2E | Dark backgrounds |
| `--white` | #FFFFFF | Text, cards |
| `--gold` | #D4AF37 | Premium/featured |

### Logo
"MD Fit." with blue gradient, period included

---

## Security & Portability

- Company-owned: Git repo, domain, hosting, database, video accounts, payments, app-store accounts, API keys
- Separate staging/production
- Role-based permissions
- Backups + restore testing
- Access logs, encryption
- Minimal sensitive data
- Privacy/HIPAA applicability review
- Documented API and deployment
- **Do NOT hardwire logic into WordPress templates**

---

## Delivery Sequence

1. Audit current code and assets
2. Agree schema/taxonomy
3. Implement auth, video library, Pain Tool
4. Complete generator + custom workouts
5. Structured programs + dashboard
6. Subscriptions + admin
7. Controlled beta + bug fixes
8. Paid movement analysis + advanced onboarding (post-beta)
9. Native iOS/Android when web stable

---

## Unresolved Questions (from spec)

- [ ] What is actually built and functional?
- [ ] Where do all source code and assets reside?
- [ ] Final 51-video checklist and full exercise inventory?
- [ ] Exact master golf/pickleball/running/ski program files?
- [ ] Current approved prices?
- [ ] Video hosting costs?
- [ ] Patient-data boundaries?
- [ ] Target iOS/Android distribution timeline?
- [ ] Owner of design files?
- [ ] Acceptance and launch dates?

---

## Project Structure

```
MDfit/
├── CLAUDE.md           # This file
├── GOALS.md            # Session snapshots
├── MDfitApp/           # iOS app (Swift/SwiftUI)
│   └── Sources/MDfit/
│       ├── App/
│       ├── Models/
│       ├── Views/
│       ├── ViewModels/
│       ├── Services/
│       └── Resources/
├── web/                # Web app (if needed before native)
└── docs/               # Specs, API docs
```

---

## Session Commands

- `/mdfit` — resume with full context
- `/mdfit-save` — append session learnings to CLAUDE.md and GOALS.md

---

## Hard Rules

1. **Educational only** — never claim medical diagnosis
2. **iOS-first** — Swift/SwiftUI, no React Native
3. **Apple Pay** — no custom Stripe on iOS
4. **Prescription on WorkoutExercise** — not on Exercise record
5. **Video naming** — `REGION_CATEGORY_MOVEMENT_SUBTYPE.mp4`
6. **Stable IDs** — content versioning for exercises
7. **No PHI in logs** — never log patient health info
8. **Offline-capable** — core features work without network
9. **Red-flag guidance** — Pain Tool shows when to seek professional help
10. **Company-owned assets** — all repos, accounts, keys owned by MD Fit

---

## Reference

- [MD Fit Website](https://mdfitsrq.com/)
- Developer Handoff PDF (Oct 22, 2026)
- Workout Generator Screenshot
