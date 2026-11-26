# Applaz Plus activation

App Store name: **Applaz - Goals Delivered**. Subtitle: **Reach your goals**.
The iPhone home-screen display name remains Applaz. The existing three-bar logo shape is retained; its pigment is black.

## App Store Connect

1. Complete Paid Apps agreements, banking and tax information. Create an auto-renewable subscription in a subscription group, product ID `com.applaz.plus.weekly`, duration **one week**, US price **$2.99**. If there are existing subscribers, review their subscription group before creating another group; this implementation preserves verified legacy ad-free access without granting AI credits.
2. Add an introductory offer: **one week free**, available to eligible customers. Apple determines eligibility. Users must confirm an actual subscription purchase through Apple to start the trial. Dismissing the welcome screen grants no credits.
3. Add localized subscription name and description, review screenshot, review account and notes. Complete App Privacy disclosures for Firebase account/private notebook storage and selected content sent to OpenAI. Publish an accurate app privacy policy URL; use Apple's standard EULA unless supplying custom terms. The in-app AI privacy screen describes selected content and offers consent/revocation.
4. In Users and Access → Integrations, create an App Store Server API key; securely retain issuer ID, key ID and private `.p8` key. Find the numeric App Store app ID. Never put private keys in the iOS app or Git.
5. Test purchase, trial eligibility, pending/canceled purchase, restore, expiration, refund/revocation and account ownership with StoreKit sandbox/TestFlight before review. Subscription review and approval are required before production availability. The paywall stays disabled until backend readiness is enabled.

## Firebase / OpenAI

The existing project remains **applaz-32772**, bundle **com.applaz**. Existing Realtime Database users/notes and photo uploader remain in place.

1. In this Firebase project create a **separate named Firestore database `applaz-wellness`**. Deploy `functions/wellness/firestore.rules` to that database only: all direct client reads and writes are denied. Do not replace the existing default database or its rules. Cloud Functions access this private database with the Admin SDK and authenticated Firebase UID.
2. Use Node 22; run `npm ci`, `npm test` and `npm run lint` in `functions`. Set secret values with Firebase CLI: `OPENAI_API_KEY`, `APPLE_IAP_PRIVATE_KEY`, `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`. The OpenAI project needs Responses API access to `gpt-5.6-luna`, a billing method and spending alerts. Keep all secrets out of Git.
3. Set environment `APPLE_APP_ID` to the numeric ID and `SANDBOX_TEST_UIDS` to comma-separated test Firebase UIDs. Sandbox has a lifetime cap of 10 real AI credits per original purchase, so accelerated renewals cannot produce unlimited paid API calls.
4. Deploy only new functions initially: `wellnessStatus`, `wellnessSync`, `wellnessChatSync`, `wellnessConsent`, `subscriptionAccess`, `wellnessAI`, `deletePrivateWellness`, `deleteDisabledPrivateWellness`. Readiness is disabled by default. After testing set `WELLNESS_ENABLED=true` and redeploy. The client checks readiness before enabling purchase. Configure Firestore TTL on privateAccounts/*/requests `expiresAt` to discard AI response caches after about one day. Raw meal images are not stored in the public Storage bucket.
5. Set server max instance and billing alerts appropriate to launch volume. The per-account transaction ledger protects the AI allowance; it does not cap all Firebase infrastructure expenses, fraudulent signups, acquisition cost or taxes. Fresh Apple status is checked before AI calls. A purchased original transaction can bind to only one Firebase UID. Account deletion removes private notebook data; an ownership/spend ledger binding is retained to prevent recycling a receipt.
6. Real payment and API verification require your configured accounts. Building the app alone does not activate a subscription. Unknown currency/price combinations fail closed; this budget policy currently accepts USD $2.99 only. Configure verified proceeds policies before opening other storefront prices.

## Usage economics (estimates, not a profit guarantee)

Model price used: input **$0.20/million tokens**, output **$1.20/million tokens**. Text input byte limits plus max 600 output tokens keep normal calls inside a reserved **$0.004 per credit**. Low-detail photo requests reserve two credits ($0.008). No tools, search or extra paid model calls are enabled. Prices and model availability must be checked again before activation.

- Trial: **10 credits total**, maximum planned AI reserve **$0.04/person**, whether used on text or photos. No credits for merely installing/skipping the paywall. 10,000 full trials reserve **$400** of AI cost, plus Firebase infrastructure. This is acquisition expense with zero trial revenue; it cannot have a 50% margin.
- Paid: **100 credits/week**, maximum planned AI reserve **$0.40/week**. Text chat, insights and typed meal estimates cost one credit; photo meal estimates cost two. A verified new billing transaction resets credits; restoring the same transaction does not. Concurrent requests reserve atomically before calling the provider. Failed/timeout requests may be billable and keep the reservation.
- At $2.99 gross and a conservative 30% Apple commission, proceeds are $2.093 before taxes/refunds. Preserving half of gross ($1.495) leaves $0.598 for variable costs. $0.40 AI reserve plus an illustrative $0.10 infrastructure allowance leaves $0.098 cushion. A 15% Apple fee improves this, but enrollment/eligibility is not assumed. Total business margin can be lower.

### 10,000 trials, 80% fail to convert after week one

Assuming 20% convert to the first charged week: 2,000 × $2.99 = **$5,980 gross**; after 30% Apple fee **$4,186**. Subtract trial AI $400, paid-week AI $800 and illustrative paid-user infrastructure $200: **$2,786 remains** before trial infrastructure, marketing, development, taxes, refunds and fixed overhead. This covers those modeled AI costs; it does not prove business break-even. 80% churn after an already-paid week is a different cohort calculation.

Ignoring all overhead, AI-only break-even requires 10,000 × $0.04 ÷ ($2.093 − $0.40) = about **237 paying users (2.37% conversion)**. Including $0.10 per paying user makes that about **252 (2.52%)**. Nonconverting-user hosting and acquisition costs increase it.

## Official references

- [Apple subscriptions and disclosures](https://developer.apple.com/app-store/subscriptions/)
- [Apple purchase interface guidance](https://developer.apple.com/design/human-interface-guidelines/apple-in-app-purchase)
- [Apple server verification library](https://github.com/apple/app-store-server-library-node)
- [OpenAI model and pricing](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [Apple standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)

## Validation completed locally

The iPhone simulator build passes. Eleven backend policy tests pass, and ESLint passes. A simulator UI test passed checking private Start Here visibility, daily checklist toggling, persistence across app termination/relaunch, and saving a reviewed manual meal into the daily diary. Preview fixtures contain local sample content, not production user data.

Live Apple purchase/restore/refund verification, OpenAI responses, cross-device private sync and actual food-photo estimates remain unverified until the accounts, product and secrets above are configured. The paywall is disabled until readiness is enabled. Do not treat these local checks as a production payment test. Confirm the Support/report email (currently info@whirlpost.co) before publishing.

## Notebook AI and mockup features

Ask my notebooks reads both the signed-in user’s existing regular notebooks and health notebooks. The regular-notebook index is read-only; existing Firebase note data is not migrated. Inline chat is present on the notebook home, notebook detail, and note editor. Saved chats, their source links, and charts are stored privately per account; cloud history requires deploying wellnessChatSync. Users can resume, start new, or delete conversations.

Charts use recorded checklist, milestone, confirmed meal, or explicitly numeric note values. The model selects a supplied metric; it cannot invent chart values. Daily, weekly, and monthly insights filter different calendar periods. Health templates include goal deadlines and milestones, weekly reflections, recurring routines, workout weekdays, sets/reps, session notes, and rich text/photos. Creative-project templates are excluded.

New notebooks default to Public with an explicit privacy choice. Start Here stays private. Explicitly public health notes publish only a sanitized current snapshot into a managed Realtime Database category; meal logs, dated reflections, and AI conversations remain private. Sharing uses separate revisions so stale edits cannot undo a privacy change. Deployment and live Firebase validation are required before relying on this publication path.

Local simulator checks passed checklist progress, goal milestones, daily/weekly/monthly controls, the regular editor’s inline composer with keyboard, saved conversation/chart persistence across relaunch, health-template creation with Private selection and note deletion menus, and Newsfeed Read more / private-copy actions. Test fixtures use isolated sample records while Firebase is offline. Live AI responses and cross-device sync are still activation checks, not locally verified results.

Final visual verification also caught and fixed a Guest notice overlay and duplicated safe-area inset on the standalone notebook tab bar. The additional simulator check passed scrollable guest registration, inline AI availability, and bottom-menu icon height.

## Mockup coverage update — build 1.0.14 (5)

New notebook offers Blank notebook, Health & fitness goals, Daily wellness, Daily workout, Food diary, and Fitness training. Both creators preserve the selected template; the UIKit template chooser preserves an explicit Private selection. Creative-project templates are excluded. Existing notebook titles/content are preserved.

Food diary notebooks now expose the confirmed daily tally and meal-entry action directly. The public-note viewer provides the same private-copy and note-scoped AI actions as Newsfeed. A copy always goes into a private Saved notes notebook, including when a public notebook has the same name. Compact chat uses aligned message bubbles and contextual input prompts. Standalone health screens carry a bottom menu with reserved layout space; screens inside the existing social tabs keep their native menu. Insights retains the selected period when returning from saved charts.

Targeted simulator checks passed for template definitions/choices, private-copy collision handling, meal-entry access, public-note copy/AI actions, template privacy retention, bottom-menu navigation/content clearance, and saved-chart navigation with Monthly selection retained. Preview charts use local sample records and labeled preview AI replies; these checks do not validate live OpenAI, Apple billing, or real-account Firebase operations.

The public wellnessStatus endpoint at the URL configured in the app returned HTTP 404 during the November 25 readiness check. The new backend is not available to the app at that address. This check does not test the existing Firebase authentication, photo storage, or social database. Subscriber policy tests pass locally; live enforcement requires backend deployment and verified Apple/OpenAI setup.

## Final insights design verification — build 1.0.14 (6)

The notebook overview now combines consistency, the recorded-values trend, Find my patterns and the inline AI composer in one card. Charts use a lilac line, outlined points, soft area shading and short date labels. Exact values remain available in Recorded values. Saved chats, New chat and AI privacy preferences remain in the AI options menu. The notebook list no longer reserves empty section spacing above the overview.

The final simulator build succeeded. Both targeted UI checks passed: the notebook overview composer fits above the bottom menu and remains usable with the keyboard; Monthly insights and saved-chart navigation retain their selected period and recorded-value disclosure. This design pass changes presentation, not Firebase configuration, billing limits or stored user data.

Refreshed App Store artwork is in AppStoreAssets/Health-Refresh. It uses native iPhone and iPad layouts with fictional offline sample records. The backend activation requirements above still apply; screenshot creation does not activate purchases, OpenAI or cloud sync.

## Reference layout corrections — build 1.0.14 (7)

The new-notebook form uses labeled Name, Template, Layout and Visibility rows, one full-width Create action, and the existing-notebook dropdown. Template choices use a compact anchored list with a selected checkmark. Both creation entry points share the same UIKit form, so template and privacy behavior remain consistent. Descriptions are available as template accessibility hints rather than taking space above the fields.

Checklist editors retain their notebook, editable title and Text/Checklist selector, with a contextual template badge. Inline AI charts are shorter on phones and source names can be expanded. These are presentation changes; existing notebook data, AI scope, purchase gating and server credit policy are preserved. Offline preview conversations are labeled sample data and do not demonstrate live OpenAI activation.


## Template dropdown refinement — build 1.0.14 (8)

The template dropdown now follows the reference's flat rows, subtle separators, lilac selection band and trailing checkmark. Rows are 48 points high with 17-point text and separate reserved space for the checkmark. The field's down-chevron is pinned to its trailing edge. Short display labels (Goals, Routine checklist, Workout checklist) do not rename stored notebook titles or change template identifiers. Public remains the default; explicit privacy choices and existing creation handlers are retained.

Manifestation screens shown in the chat are concept mockups only. No manifestation tools or generated concept images are included in the app.

The build and focused simulator UI check passed. Verification covered opening after keyboard entry, row spacing, selected-state indication, outside dismissal, privacy retention across template changes, and notebook creation. Fresh native previews are in DesignPreviews/dropdown-refinement.


## Translucent large actions — build 1.0.14 (9)

Create Notebook and the large authentication, subscription and meal-confirmation actions now use pale translucent surfaces, dark labels and a subtle outline in place of solid navy fills. Existing action handlers, purchase gating and disabled states remain in place. Navy remains the accent for small icons, selection and checklist state. The simulator build passed. Store artwork includes a seventh matching New Notebook screenshot for iPhone and iPad.
