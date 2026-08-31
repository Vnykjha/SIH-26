# web_dashboard — React + Chart.js (Tier 2)

District health officer / MDoNER admin view. Reads from Firestore only —
never talks to phones directly.

## Structure

- `src/pages/` — Overview, Camp/District Drilldown, (Tier 3: GIS Map)
- `src/components/` — RiskBreakdownChart, ScreeningsTable, DistrictFilter, etc.
- `src/services/` — firestoreService (read-only queries)

## Not yet implemented — build order suggestion

1. Scaffold with Vite or CRA (`npm create vite@latest . -- --template react`)
2. `src/services/firestoreService.js` — connect to same Firebase project as mobile_app
3. `src/pages/OverviewPage.jsx` — totals + risk breakdown (Chart.js)
4. `src/components/ScreeningsTable.jsx` — filterable by camp/district
5. Tier 3: GIS heatmap layer (ISRO Bhuvan or similar)
