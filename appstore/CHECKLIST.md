# MyFridge: path to the App Store

Status of each item: **DONE** (in this repo), **YOU** (needs your Apple account, a Mac, or your decision).

## 0. Already done in the code
- DONE App icon (1024x1024, no transparency)
- DONE Widget and app share data through the App Group `group.johnmorchaw.MyFridge`
- DONE Sign-in bypass removed, paywall claims made truthful, camera permission text added
- DONE English + Quebec French UI, notifications, widget and permission prompts
- DONE Scanner rewrite and tests
- DONE Export compliance answered in the build settings (standard encryption only)
- DONE iPhone-only (no iPad screenshots or iPad review needed)
- DONE Privacy policy + support pages in `docs/` (English and French)
- DONE Listing text in `LISTING_EN.md` / `LISTING_FR.md`

## 1. Fill the placeholders (YOU, 10 minutes)
1. `MyFridge/MyFridge/AppLinks.swift`: replace `support@example.com` with a mailbox you read.
2. `docs/privacy.html` and `docs/index.html`: replace `[YOUR SUPPORT EMAIL]` / `[VOTRE COURRIEL DE SOUTIEN]`.
3. Both listing files: replace `[YOUR PRIVACY POLICY URL]` once step 2 is live.

## 2. Host the privacy policy for free (YOU, 5 minutes)
GitHub repo > Settings > Pages > Source: **Deploy from a branch** > Branch `main`, folder `/docs` > Save.
Your URLs will be:
- Support URL: `https://josephandraos.github.io/MyFridge/`
- Privacy Policy URL: `https://josephandraos.github.io/MyFridge/privacy.html`

### Put the in-app privacy link back (needed for subscriptions)
Apple guideline 3.1.2 requires working Privacy Policy and Terms links **inside** an app that sells auto-renewing subscriptions. They were removed on request; restore them once the URL above works:

`AppLinks.swift`, add:
```swift
static let privacyPolicy = URL(string: "https://josephandraos.github.io/MyFridge/privacy.html")!
```
`PremiumFeaturesSheet.swift`, inside the `HStack` with "Terms of Use", add:
```swift
Link("Privacy Policy", destination: AppLinks.privacyPolicy)
```
(Optional) a "Privacy Policy" row in `SettingsView` next to "Terms of Service". Add the French text "Politique de confidentialité" for the key "Privacy Policy" in `Localizable.xcstrings`.

## 3. Apple Developer portal (YOU)
- Identifiers: make sure `johnmorchaw.MyFridge` and `johnmorchaw.MyFridge.MyFridgeWidget` exist.
- Register the App Group `group.johnmorchaw.MyFridge`.
- Both identifiers need the **App Groups** capability; the app also needs **Sign in with Apple**.
  (Xcode "Automatically manage signing" usually does this for you; step 4 checks it.)

## 4. On a Mac in Xcode (YOU, the part I cannot do)
1. `git clone https://github.com/josephandraos/MyFridge` and open `MyFridge/MyFridge.xcodeproj`.
2. Select each target (MyFridge, MyFridgeWidgetExtension) > Signing & Capabilities: Team `RV997F4M6J`, **App Groups** shows `group.johnmorchaw.MyFridge` ticked, the app also has **Sign in with Apple**.
3. **Product > Test (Cmd+U).** Send me any failures: I wrote this code without a compiler, so expect some small fixes.
4. Run on a **real iPhone** and check: sign in with Apple, add an item, scan a real receipt, get a reminder, widget shows items, ticking an item in the widget removes it in the app, switch the phone to French and look at every screen.
5. StoreKit testing: Edit Scheme > Run > Options > StoreKit Configuration = `Products.storekit`, then try both subscriptions.

## 5. App Store Connect (YOU)
1. **My Apps > + > New App.** Platform iOS, name `MyFridge`, primary language English (Canada) *or* French (Canada), bundle ID `johnmorchaw.MyFridge`, any SKU (e.g. `myfridge-001`).
2. **Subscriptions:** create group `Premium`, then two auto-renewable subscriptions with these **exact** Product IDs:
   - `myfridge.premium.monthly`, 1 month, 2.99 CAD
   - `myfridge.premium.yearly`, 1 year, 29.99 CAD

   Add English and French display name/description (see the listing files) and a review screenshot of the paywall for each.
3. **Add French (Canada) as a second language** and paste `LISTING_FR.md`; paste `LISTING_EN.md` for English.
4. **App Privacy:** choose **Data Not Collected** (the app has no network code, analytics or tracking; see `docs/privacy.html`).
5. **Age rating:** answer "None" to everything: result 4+.
6. **Category:** Primary Food & Drink, secondary Lifestyle.
7. **Pricing and availability:** Free app; availability Canada (add other countries later if you want).
8. **URLs:** Support URL and Privacy Policy URL from step 2. Copyright: `2026 <your name>`.
9. **Screenshots (required):** iPhone 6.9" (1320 x 2868). Take 3 to 6 in the simulator (iPhone 16 Pro Max): home, items list, scanner, review screen, widget, paywall. Make a French set too.
10. **App Review Information:**
    - Sign-in: the app uses Sign in with Apple (no demo account needed).
    - Notes: see `REVIEW_NOTES.md`.
    - Contact phone and email: yours.

## 6. Upload and submit (YOU)
1. Xcode: pick **Any iOS Device (arm64)**, **Product > Archive**.
2. Organizer > **Distribute App > App Store Connect > Upload**.
3. In App Store Connect, wait for the build to finish processing, attach it to version 1.0, attach both subscriptions to the version, and press **Add for Review > Submit**.
4. Recommended first: send the build to **TestFlight** and scan 5 to 6 real receipts for a few days. Real receipts will expose scanner problems my synthetic test receipts could not.

## 7. Things most likely to cause a rejection
- Missing in-app Privacy Policy link next to the subscription (section 2).
- The paywall promises something that does not exist (already cleaned up).
- A crash on launch because the App Group is not enabled on both targets (section 4, step 2).
- Reviewer cannot reach the scanner: see `REVIEW_NOTES.md`; attach a sample receipt.
