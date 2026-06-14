# App Review — notes & compliance record

## Notes for the App Review team (paste into App Store Connect → App Review Information → Notes)

Tennis Score is a free, fully offline tennis scoreboard. No account or sign-in is required — the app opens straight to the home screen. It makes no network calls and collects no data (App Privacy: Data Not Collected). There are no in-app purchases and no ads.

Two modes:
- "Match": classic tennis scoring. On the match screen, tap either half of the screen to award that player a point; swipe down to undo.
- "105": a coach's practice game. Score by shot type using the large buttons on each side; point values are configurable in Settings. Play to a target score (default 105).

No demo account needed. All features are available immediately and offline.

---

## Internal compliance audit (adversarial review against App Store Guidelines)

This kit was audited against the App Store Review Guidelines. Verdict at the time of audit: the app, binary and written copy are review-ready; the only blockers were stale marketing screenshots from a removed feature — now fixed.

**Character limits:** All fields PASS. appName \"Tennis Score\" = 12/30 PASS. subtitle \"Offline tennis scorekeeper\" = 26/30 PASS. promotionalText = 120/170 PASS. keywords = 96/100 PASS (14 terms; App Store counts the raw comma-separated string, so 96 is the binding count — well under 100, with no wasted spaces). description = 1974/4000 PASS. whatsNew is comfortably under the 4000 limit. No field exceeds its cap.

**Copy:** Text copy itself is clean and within all limits — no edits strictly required for the written fields. One recommended change for trademark safety (5.2.5): in the description, change the line \"Four court themes: Wimbledon grass, Roland Garros clay, US Open blue and Melbourne blue\" to generic surface names, e.g. \"Four court themes: grass, clay, blue hard and Melbourne blue\" (and rename the in-app theme labels to match). No superlatives or banned claims are present; \"done right\" and \"Made to look good\" are acceptable puffery. \"Free, no ads, no sign-in, fully offline\" is accurate and verifiable against the binary, so it is safe. Keywords contain no trademarks and no competitor names — leave as is. Note: the real problems are the stale SCREENSHOTS, not the copy.

### Findings and how each was resolved

### 2.3.3 — Submission screenshot home.png advertises a "Pro trial" the app no longer has  
**Risk:** HIGH  
**Issue:** AppStore/screenshots/home.png (the first screenshot reviewers see) shows a prominent badge "Pro trial - 23h 59m left". This is a stale screenshot captured from the old subscription build (commit 079e56e "Подписка Pro $2.99/мес: StoreKit 2, пробный день"). The subscription was later removed (commit aa69180 "Убрана подписка — приложение бесплатное"), and the current source contains zero StoreKit/paywall/trial code (grep for storekit|subscription|paywall|trial returns nothing in App/Sources). The screenshot therefore depicts a feature that does not exist in the binary and directly contradicts the listing's own "No in-app purchases" claim. App Review treats screenshots as part of the metadata that must reflect the actual app; a paid-trial badge on a free app with no IAP is a textbook 2.3.3 / 2.3.1 rejection.  
**Resolution:** Recapture home.png from the current free build so no "Pro trial" badge appears, and replace AppStore/screenshots/home.png. Delete the stale source assets screenshots/auth.png, screenshots/auth_dark.png, screenshots/paywall.png, screenshots/paywall_dark.png and the trial-era home/settings shots so they cannot be uploaded by mistake.

### 2.3.1 — Submission screenshot settings.png shows an Account/Subscription section, email sign-in, and a $2.99 Subscribe button  
**Risk:** HIGH  
**Issue:** AppStore/screenshots/settings.png contains a full "ACCOUNT & SUBSCRIPTION" block: "efremovwwwork@rambler.ru — Signed in with Email" with a "Sign out" button, and "Trial - 23h 59m left / $2.99 / month after the free day" with a "Subscribe" button. None of this exists in the shipping app (no account, no sign-in, no IAP per APP FACTS and confirmed by the source — no entitlements file, no StoreKit). This both misrepresents the app and exposes hidden/removed monetization, which reviewers read as 2.3.1 (undocumented/hidden features) and 2.3.7 (mention of pricing in screenshots that doesn't match the product). It also flatly contradicts the App Privacy "Data Not Collected" answer and the listing's "no sign-in" copy, inviting scrutiny of the privacy declaration.  
**Resolution:** Recapture settings.png from the current build (which has no Account/Subscription section, no sign-in, no Subscribe button) and replace AppStore/screenshots/settings.png. Verify every uploaded screenshot is from a build at or after commit aa69180.

### 4.2 — Minimum Functionality — assessed: passes, but it is a scorekeeping utility so present the depth  
**Risk:** LOW  
**Issue:** Reviewers scrutinize single-purpose scoring/counter apps under 4.2. However this app clears the bar comfortably: two distinct modes, a real rules engine (MatchConfig/MatchEngine/Game105Engine with unit tests covering deuce/advantage, no-ad deciding point, 7-point and 10-point super tiebreaks, best-of-3/5, win-by-2), customizable point values with savable presets, full undo/redo, history persistence via SwiftData, four themes, accessibility, and result sharing. All description claims are backed by actual code, so there is no over-claim gap feeding a 4.2 finding. The only residual risk is a reviewer perceiving it as a thin "counter," which the screenshots and two-mode depth rebut.  
**Resolution:** No code change needed. Ensure the screenshot set leads with the two modes and the 105 customization/presets so the depth is visible; the corrected home and 105/settings shots already do this once the stale ones are replaced.

### 5.2.5 — Real tournament names (Wimbledon, Roland Garros, US Open) used as in-app theme labels  
**Risk:** MEDIUM  
**Issue:** CourtTheme.swift hard-codes the registered tournament marks as visible UI labels ("Wimbledon", "Roland Garros", "US Open") and the description and settings.png surface them. "Wimbledon", "Roland-Garros" and "US Open" are protected trademarks of the AELTC / FFT / USTA. Using them as feature/theme names — and especially pairing each with that event's signature surface color (grass green/purple, clay orange, hard blue) — can read as implying affiliation or endorsement, which App Review flags under 5.2.5 (use of third-party trademarks/IP) and can also draw a metadata-IP rejection. The keywords field is correctly clean of these marks (good), but the in-app labels and the description line "Four court themes: Wimbledon grass, Roland Garros clay, US Open blue" are the exposure.  
**Resolution:** Rename the themes to generic surface descriptors already present in the code as subtitles — e.g. "Grass" (London green/purple), "Clay" (Paris orange), "Hard - Blue" (New York), keeping "Melbourne"/"Hard" which is a city, not a mark. Update CourtTheme.title strings, the description line, and recapture settings.png. If the names are kept, be prepared to show written authorization from each rights holder, which is the only way 5.2.5 is satisfied.

### 5.1.1 — App Privacy "Data Not Collected" — correct, and a genuine strength  
**Risk:** LOW  
**Issue:** Source confirms no network code (no URLSession/URLRequest/http), no CloudKit/iCloud, no entitlements file, no third-party SDKs, and SwiftData is local-only. On-device-only storage of match history, names, presets and settings is explicitly not "collection" under Apple's definition, so "No, we do not collect data" and the "Data Not Collected" label are accurate. This is a positive signal for review. The one thing that could undercut it is the stale settings.png showing an email account and sign-in, which a reviewer could read as contradicting the no-data declaration.  
**Resolution:** Keep the "Data Not Collected" answer. The only action is fixing settings.png (see 2.3.1) so the screenshots don't imply an account/identity that would conflict with the privacy declaration. No PrivacyInfo.xcprivacy collection entries are needed; ensure NSPrivacyTracking is false if the file is included.

### 1.5 — Privacy policy and support URL contain unfilled placeholders  
**Risk:** MEDIUM  
**Issue:** The privacy policy and support page still contain bracketed placeholders: "[INSERT DATE...]", "[INSERT CONTACT EMAIL, e.g. support@example.com]". App Review requires a functional privacy policy URL and a support URL with a real, working contact method (1.5 Developer Information / metadata). A live policy page showing "[INSERT CONTACT EMAIL]" or no reachable contact is grounds for a metadata rejection.  
**Resolution:** Replace every [INSERT ...] placeholder with the real effective date and a monitored support email before hosting the pages, and enter the live URLs in App Store Connect (Support URL is required; Privacy Policy URL is required).

### 2.3.8 — Placeholder text/email in 9:41 status-bar marketing shots is fine, but verify final names aren't placeholder-looking  
**Risk:** LOW  
**Issue:** Screenshots use sample data (Anna/Maria, Eagles/Hawks, efremovwwwork@rambler.ru). Sample player names are acceptable, but the visible developer email and the trial copy reinforce the stale-screenshot problem. 2.3.8 prohibits placeholder/irrelevant content in metadata; once the two stale shots are replaced this is moot.  
**Resolution:** After recapturing home.png and settings.png, confirm no developer email or placeholder/trial text remains visible in any uploaded screenshot.

### Resolution log (what changed after the audit)
- **2.3.3 / 2.3.1 — stale screenshots (HIGH):** RESOLVED. All screenshots regenerated from the current free build (commit at/after the subscription removal). `home.png` no longer shows a trial badge; `settings.png` no longer shows an account/subscription section. Stale `auth.png`/`paywall.png` captures deleted.
- **5.2.5 — tournament trademarks (MEDIUM):** RESOLVED. Court themes renamed to neutral surface descriptors (Grass / Clay / Hard · Blue / Melbourne) in `CourtTheme.swift`; the App Store description uses generic surface wording. No trademarks remain in UI labels, description, or keywords.
- **1.5 — privacy/support placeholders (MEDIUM):** ACTION REQUIRED BY YOU. Fill the effective date and a real contact email in `PRIVACY_POLICY.md` and `SUPPORT.md`, then host both and enter the URLs in App Store Connect.
- **4.2 / 5.1.1:** PASS, no change needed (genuine two-mode depth; no data collected).

**Overall:** Likely to be REJECTED on first submission as currently assembled — not because of the app or the written copy (the binary is complete, the features genuinely match the description, limits all pass, and \"Data Not Collected\" is accurate and a plus), but because two of the six submission screenshots (AppStore/screenshots/home.png and settings.png) are stale captures from the removed-subscription build. home.png shows a \"Pro trial - 23h 59m left\" badge and settings.png shows an \"ACCOUNT & SUBSCRIPTION\" section with email sign-in and a $2.99 \"Subscribe\" button — none of which exist in the shipping free app, triggering 2.3.3 / 2.3.1 and contradicting the listing's own \"no IAP, no sign-in\" claims and the privacy declaration. Biggest single risk: those stale screenshots. Neutralize by recapturing home.png and settings.png from the current build (commit aa69180 or later), deleting the auth/paywall source assets so they can't be re-uploaded, and confirming every uploaded image is trial- and account-free. Secondary must-fix before submission: fill the [INSERT DATE/EMAIL] placeholders in the privacy policy and support page (1.5). Recommended: rename the Wimbledon/Roland Garros/US Open themes to generic surface descriptors to remove the 5.2.5 trademark exposure. With those three fixes, the app is well-positioned to pass.
