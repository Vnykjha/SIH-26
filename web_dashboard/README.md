# web_dashboard — React + Chart.js (Tier 2)

District health officer / MDoNER admin view. Reads from Firestore only —
never talks to phones directly.

## Structure

- `src/pages/` — Overview, Camp/District Drilldown, (Tier 3: GIS Map)
- `src/components/` — RiskBreakdownChart, ScreeningsTable, DistrictFilter, etc.
- `src/services/` — firestoreService (read-only queries)

## Implemented

- Responsive overview for district health officers and MDoNER administrators
- Total screenings, high-risk count, average WOMAC, and average age metrics
- Risk breakdown doughnut chart and district activity bar chart
- District and risk-level filters for recent screening records
- State and district filters for the eight Northeast states; district codes are normalized so spacing and capitalization variations (for example, `District-01 Assam` and `district -01 assam`) group together.
- Firestore read-only integration with support for the flattened records written by
	`mobile_app/lib/services/sync_service.dart`
- Clearly labeled sample records when Firestore is not configured or unavailable

GIS heatmap is intentionally not included.

## Run locally

```bash
npm install
npm run dev
```

To connect to the real Firebase project, create a `.env` file in this directory
with the `VITE_FIREBASE_*` values used by `src/services/firebase_config.js`.

## Deploy remotely with Firebase Hosting

From the repository root, install and authenticate the Firebase CLI once:

```powershell
npm.cmd install -g firebase-tools
firebase.cmd login
```

Then select the same Firebase project used by the mobile app and deploy:

```powershell
cd d:\sih-oa-screening
firebase.cmd use YOUR_FIREBASE_PROJECT_ID
firebase.cmd deploy --only hosting
```

The hosting configuration builds `web_dashboard` and publishes its `dist`
directory. The SPA rewrite keeps dashboard routes working after refresh.

The Android app also needs the Firebase Android configuration at
`mobile_app/android/app/google-services.json`. Once that file is present, the
app initializes Firebase on launch, uploads pending SQLite screenings after a
screening is saved, and the dashboard listens to the same `screenings` collection
in real time.

## Admin-only dashboard access

The dashboard uses Firebase Email/Password Authentication. Create the admin
account under **Firebase Console → Authentication → Users**, then copy that
user's UID. In **Firestore Database → Data**, create an `admins` collection
with a document whose ID is exactly that UID and whose field is
`role` (string) = `admin`. The dashboard verifies this document before reading
screenings.

The repository's `firestore.rules` allow authenticated mobile users to upload
screenings associated with their Firebase UID (`uploaded_by`), allow only
listed admins to read screening records, and prevent clients from changing the
admin list or deleting screenings. Review the rules for your deployment before
publishing them. From the repository root, select the intended Firebase project
and deploy the rules:

```powershell
firebase.cmd use crepisense
firebase.cmd deploy --only firestore:rules
```

Deploy the dashboard separately after its Firebase environment variables are
configured:

```powershell
firebase.cmd deploy --only hosting
```
