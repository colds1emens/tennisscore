## App Store Connect — App Privacy answers for Tennis Score

**Data Collection: NO.**

### First question

App Store Connect's App Privacy section begins by asking:

> "Do you or your third‑party partners collect data from this app?"

**Select: "No, we do not collect data from this app."**

This is the correct and accurate answer for Tennis Score. After selecting it, App Store Connect will not ask any further questions about data types, and the app's product page will display **"Data Not Collected."** You then click Publish to save it.

### Why "No" is correct here

Apple defines "collect" as transmitting data off the device and/or accessing it in a way that makes it available to you or your partners for more than the time needed to service the request on‑device. Tennis Score does none of that:

- **No network at all.** The app makes zero network calls and works fully offline, so nothing is ever transmitted off the device.
- **No servers, no account, no sign‑in.** There is no backend that could receive data, and the app never asks for a name, email, or any contact detail tied to an identity.
- **No analytics, crash reporting, tracking, or third‑party SDKs.** Nothing observes or reports usage.
- **No advertising and no identifiers.** The app does not use IDFA, `identifierForVendor`, or any device identifier, and shows no ads.
- **On‑device storage is not "collection."** Match/game history, the player and team names you type, custom rule presets, and app settings are saved only on your iPhone using Apple's on‑device storage (SwiftData and the system settings store). Apple's own guidance is explicit that data stored only on the device and not sent anywhere is not "collected." There is no iCloud/CloudKit sync.
- **Result sharing is user‑initiated and not transmitted by us.** Sharing a result image happens only when the user taps Share and uses the standard iOS share sheet; the app does not upload anything itself, so it does not count as collection.

### Related declarations

- **Tracking:** No. The app does not track users across apps or websites owned by other companies, so no App Tracking Transparency prompt and no tracking declaration are needed.
- **In Xcode / build settings:** `ITSAppUsesNonExemptEncryption` is set to NO (the app uses no non‑exempt encryption), which is consistent with an offline, no‑data app.
- **No privacy manifest data‑collection entries** are required because no data is collected. (If a `PrivacyInfo.xcprivacy` file is included, `NSPrivacyTracking` should be false and `NSPrivacyCollectedDataTypes` should be empty.)

### Summary

For every data category App Store Connect could present (Contact Info, Health, Financial, Location, Identifiers, Usage Data, Diagnostics, etc.), the answer is **not collected**. The single top‑level answer "No, we do not collect data from this app" fully and truthfully covers the questionnaire, resulting in a **"Data Not Collected"** label on the App Store.
