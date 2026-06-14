# App Store submission kit — Tennis Score

Everything needed to publish the app, version 1.0.0, bundle id `com.efremov.tennisscore`.

## Files
| File | What it is | Where it goes |
|------|-----------|---------------|
| [SUBMISSION_GUIDE.md](SUBMISSION_GUIDE.md) | Step-by-step, start here | — |
| [METADATA.md](METADATA.md) | Name, subtitle, description, keywords, what's new | App Store Connect → app page (limits verified) |
| [PRIVACY_POLICY.md](PRIVACY_POLICY.md) | Privacy policy text | host publicly, paste URL in ASC |
| [SUPPORT.md](SUPPORT.md) | Support page text | host publicly, paste URL in ASC |
| [APP_PRIVACY.md](APP_PRIVACY.md) | Exact App Privacy questionnaire answers | ASC → App Privacy (→ "Data Not Collected") |
| [REVIEW_NOTES.md](REVIEW_NOTES.md) | Notes for the reviewer + compliance audit | ASC → App Review Information → Notes |
| [ExportOptions.plist](ExportOptions.plist) | Export template for `make ipa` | used by the build |
| [screenshots/](screenshots) | 6 iPhone shots, 1320×2868 (6.9") | ASC → screenshots → **iPhone 6.9"** |
| [screenshots/ipad/](screenshots/ipad) | 6 iPad shots, 2064×2752 (13") | ASC → screenshots → **iPad 13"** |

> The app is **universal (iPhone + iPad)**, so App Store Connect requires **both** a 6.9" iPhone set **and** a 13" iPad set. Both are ready in the folders above.

## Build commands (from repo root)
```bash
make archive TEAM_ID=XXXXXXXXXX   # release .xcarchive (your 10-char Team ID)
make ipa     TEAM_ID=XXXXXXXXXX   # export .ipa → build/ipa/ → upload via Transporter
```
Or archive in Xcode: **Product → Destination = Any iOS Device → Product → Archive → Distribute App**.

## Before you submit — 3 things only you can do
1. **Enroll** in the Apple Developer Program ($99/yr) and get your Team ID.
2. **Fill placeholders** in `PRIVACY_POLICY.md` and `SUPPORT.md`: the effective date and a real contact email (search `INSERT`). Then host both pages.
3. **Sign** with your team in Xcode (Automatic signing) and upload.

## Status
- Binary: free, offline, no account, no IAP, no data collected ✓
- **Universal: iPhone + iPad, all orientations, adaptive layout** ✓
- Release build compiles, version 1.0.0, encryption declared ✓
- Screenshots: current build, no removed-feature artifacts — iPhone 6.9" + iPad 13" ✓
- Listing copy: within all character limits ✓
- Trademark-safe theme names ✓
- App Review compliance audit: passed after fixes (see REVIEW_NOTES.md) ✓
