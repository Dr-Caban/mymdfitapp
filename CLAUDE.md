# MD Fit SRQ — Claude Code Context

## Identity & Business

**MD Fit SRQ** — Physical rehabilitation & fitness practice in Sarasota, FL. Muscle-focused therapy that traces pain to its root cause.

- **Owner**: Dr. Jared Caban
- **Location**: 3214 Clark Road, Sarasota, FL 34231
- **Phone**: 941.313.0562
- **Hours**: Mon–Fri 9 AM – 5 PM
- **Website**: mdfitsrq.com
- **Booking**: ClientSecure (jared-caban.clientsecure.me)

### Core Philosophy
> "Pain Has Haunted You Long Enough"
> Fix the muscle → restore the movement → remove the pain

Not a gym. Not surface-level treatment. Specialized physiotherapy addressing tension, trauma, movement patterns, and years of compensation.

### Services
- Physical Rehabilitation
- Functional Mobility
- Active Release & Soft Tissue Manipulation
- Neck & Shoulder Pain
- Lower Back Pain
- Knee & Leg Issues
- Sports Injury Recovery
- Post-Surgical Rehabilitation
- Mobility & Flexibility Restoration

---

## Brand Identity

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| `--primary` | #FF7A00 | Orange accent, CTAs |
| `--dark` | #1A1A2E | Dark blue/purple, backgrounds |
| `--white` | #FFFFFF | Text on dark |
| `--gray` | #8A8A8A | Secondary text |

### Typography
- Clean, medical-professional aesthetic
- Sans-serif primary (SF Pro for iOS)

---

## App Architecture (iOS First)

### Platform Strategy
**iOS (Swift/SwiftUI)** → then Android (Kotlin) or cross-platform

iOS-native gives us:
- Apple Health integration (HealthKit)
- Apple Pay (no Stripe complexity)
- Face ID / Touch ID authentication
- Push notifications (APNs)
- App Store distribution
- Privacy by design

### Core Features (MVP)
1. **Booking** — Schedule appointments with Dr. Jared
2. **Progress Tracking** — Pain levels, mobility assessments, session notes
3. **Exercise Library** — Prescribed movements with video demos
4. **Messaging** — Secure communication with practitioner
5. **Payments** — Apple Pay for sessions/packages

### Data Model
```swift
// Core entities
User — patient profile, health data consent
Appointment — date, time, type, status, notes
Exercise — name, video URL, instructions, category
ProgressEntry — date, pain level, mobility score, notes
Message — sender, content, timestamp, read status
```

---

## Project Structure

```
MDfit/
├── CLAUDE.md           # This file
├── GOALS.md            # Session snapshots
├── MDfit/              # iOS app (Xcode project)
│   ├── MDfit.xcodeproj
│   ├── MDfit/
│   │   ├── App/
│   │   │   ├── MDfitApp.swift
│   │   │   └── ContentView.swift
│   │   ├── Models/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Services/
│   │   └── Resources/
│   └── MDfitTests/
└── docs/               # Design specs, API docs
```

### Architecture Pattern
**MVVM** with SwiftUI
- Models: Data structures
- Views: SwiftUI views
- ViewModels: ObservableObject classes
- Services: API, HealthKit, Auth

---

## Deploy Chain

### iOS
```
Local Xcode → TestFlight → App Store Connect → App Store
```

### Backend (if needed)
- Firebase or Supabase for auth + database
- Or integrate directly with ClientSecure API if available

---

## Session Commands

- `/mdfit` — resume with full context
- `/mdfit-save` — append session learnings to CLAUDE.md and GOALS.md

---

## Hard Rules

1. **iOS-first** — Swift/SwiftUI, no React Native or Flutter
2. **Apple Pay only** — no custom Stripe integration on iOS
3. **HIPAA-aware** — health data requires proper consent flows
4. **No PHI in logs** — never log patient health information
5. **HealthKit opt-in** — always request permission, graceful fallback
6. **Offline-capable** — core features work without network
7. **Accessibility** — VoiceOver support, Dynamic Type
8. **Dark mode** — support both light and dark appearances

---

## Current Phase

**Phase 0: Project Setup**
- [ ] Create Xcode project
- [ ] Configure bundle ID, signing
- [ ] Set up basic navigation structure
- [ ] Design system (colors, typography, components)

**Phase 1: Core Booking**
- [ ] Calendar view for available slots
- [ ] Book/cancel appointments
- [ ] Push notification reminders

**Phase 2: Progress Tracking**
- [ ] Pain level logging (1-10 scale)
- [ ] Mobility assessments
- [ ] Progress charts over time

**Phase 3: Exercise Library**
- [ ] Video player for exercises
- [ ] Categorized exercise list
- [ ] Prescribed routines

---

## Reference

- [MD Fit Website](https://mdfitsrq.com/)
- [ClassPass Profile](https://classpass.com/studios/md-fit-sarasota)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
