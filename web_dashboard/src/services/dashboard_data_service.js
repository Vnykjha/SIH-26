import { db, isFirebaseConfigured } from "./firebase_config";
import { collection, getDocs, query, orderBy, limit, onSnapshot } from "firebase/firestore";
import { getScreeningLocation } from "./location_utils";

const DEMO_SCREENINGS = [
  { id: "demo-01", name: "Anita Sharma", age: 58, sex: "female", camp_id: "Kohima-04", district: "Kohima", risk_level: "high", confidence: 0.91, total_womac_score: 62, created_at: "2026-09-04T08:42:00.000Z" },
  { id: "demo-02", name: "Biren Das", age: 46, sex: "male", camp_id: "Imphal-02", district: "Imphal West", risk_level: "medium", confidence: 0.78, total_womac_score: 39, created_at: "2026-09-04T08:18:00.000Z" },
  { id: "demo-03", name: "Lalhmingliani Pachuau", age: 67, sex: "female", camp_id: "Aizawl-01", district: "Aizawl", risk_level: "high", confidence: 0.88, total_womac_score: 71, created_at: "2026-09-04T07:56:00.000Z" },
  { id: "demo-04", name: "Tashi Norbu", age: 39, sex: "male", camp_id: "Gangtok-03", district: "East Sikkim", risk_level: "low", confidence: 0.84, total_womac_score: 12, created_at: "2026-09-03T16:14:00.000Z" },
  { id: "demo-05", name: "Maya Devi", age: 52, sex: "female", camp_id: "Shillong-05", district: "East Khasi Hills", risk_level: "medium", confidence: 0.73, total_womac_score: 34, created_at: "2026-09-03T15:40:00.000Z" },
  { id: "demo-06", name: "Rakesh Singh", age: 44, sex: "male", camp_id: "Kohima-04", district: "Kohima", risk_level: "low", confidence: 0.89, total_womac_score: 18, created_at: "2026-09-03T14:05:00.000Z" },
  { id: "demo-07", name: "Daisy Kikon", age: 61, sex: "female", camp_id: "Dimapur-02", district: "Dimapur", risk_level: "high", confidence: 0.86, total_womac_score: 58, created_at: "2026-09-03T12:22:00.000Z" },
  { id: "demo-08", name: "Pema Bhutia", age: 35, sex: "male", camp_id: "Gangtok-03", district: "East Sikkim", risk_level: "low", confidence: 0.92, total_womac_score: 9, created_at: "2026-09-03T10:47:00.000Z" }
];

function flattenScreening(doc) {
  const data = doc.data ? doc.data() : doc;
  const patient = data.patient || {};
  const risk = data.risk_result || {};
  const questionnaire = data.questionnaire || {};
  const recorder = data.recorded_by_name || data.recorded_by_display_name || data.recorded_by;
  const recorderName =
    typeof recorder === "string" && !/^[A-Za-z0-9_-]{20,}$/.test(recorder)
      ? recorder
      : "Health worker";
  const location = getScreeningLocation({
    district: data.district || patient.district,
    state: data.state || patient.state
  });
  return {
    id: doc.id || data.screening_id,
    ...data,
    ...patient,
    ...questionnaire,
    ...risk,
    ...location,
    name: data.name || patient.name || "Unnamed patient",
    recorded_by: recorderName,
    risk_level: data.risk_level || risk.risk_level || "low",
    total_womac_score: data.total_womac_score ?? questionnaire.total_womac_score ?? 0,
    created_at: data.created_at?.toDate?.()?.toISOString?.() || data.created_at || new Date().toISOString()
  };
}

function riskKey(value) {
  const normalized = String(value || "low").toLowerCase();
  return normalized === "med" ? "medium" : normalized;
}

/**
 * CREPISENSE Dashboard Data Service
 * Provides data fetch abstractions and real-time listeners for district & MDoNER dashboard analytics.
 */
export const DashboardDataService = {
  /**
   * Fetches overall aggregate screening statistics.
   */
  async fetchScreenings() {
    if (!isFirebaseConfigured) {
      return DEMO_SCREENINGS.map((screening) => ({
        ...screening,
        ...getScreeningLocation(screening)
      }));
    }

    try {
      const snapshot = await Promise.race([
        getDocs(collection(db, "screenings")),
        new Promise((_, reject) => setTimeout(() => reject(new Error("Firestore request timed out")), 4000))
      ]);
      return snapshot.docs.map(flattenScreening);
    } catch (error) {
      console.error("Unable to fetch Firestore screenings.", error);
      return [];
    }
  },

  async fetchScreeningMetrics() {
    const screenings = await this.fetchScreenings();
    const counts = screenings.reduce((result, screening) => {
      result[riskKey(screening.risk_level)] = (result[riskKey(screening.risk_level)] || 0) + 1;
      result.womac += Number(screening.total_womac_score || 0);
      result.age += Number(screening.age || 0);
      return result;
    }, { low: 0, medium: 0, high: 0, womac: 0, age: 0 });
    return {
      totalScreenings: screenings.length,
      lowRiskCount: counts.low || 0,
      mediumRiskCount: counts.medium || 0,
      highRiskCount: counts.high || 0,
      avgWomacScore: screenings.length ? (counts.womac / screenings.length).toFixed(1) : "0.0",
      avgPatientAge: screenings.length ? (counts.age / screenings.length).toFixed(1) : "0.0"
    };
  },

  /**
   * Fetches risk breakdown grouped by district.
   */
  async fetchDistrictRiskDistribution() {
    try {
      const colRef = collection(db, "screenings");
      const snapshot = await getDocs(colRef);
      const districtMap = {};

      snapshot.forEach((doc) => {
        const data = flattenScreening(doc);
        const district = data.location_label;
        const risk = riskKey(data.risk_level);

        if (!districtMap[data.location_key]) {
          districtMap[data.location_key] = { district, low: 0, medium: 0, high: 0, total: 0 };
        }

        districtMap[data.location_key].total++;
        if (risk === "high") districtMap[data.location_key].high++;
        else if (risk === "medium" || risk === "med") districtMap[data.location_key].medium++;
        else districtMap[data.location_key].low++;
      });

      return Object.values(districtMap);
    } catch (error) {
      console.error("Error fetching district distribution:", error);
      return [];
    }
  },

  /**
   * Subscribes to real-time screening updates.
   */
  subscribeToRealtimeScreenings(onDataUpdate, maxRecords = 50, onError = () => {}) {
    if (!isFirebaseConfigured) {
      onDataUpdate(DEMO_SCREENINGS.map((screening) => ({
        ...screening,
        ...getScreeningLocation(screening)
      })));
      return () => {};
    }
    const q = query(
      collection(db, "screenings"),
      orderBy("created_at", "desc"),
      limit(maxRecords)
    );

    return onSnapshot(q, (snapshot) => {
      const screenings = [];
      snapshot.forEach((doc) => screenings.push(flattenScreening(doc)));
      onDataUpdate(screenings);
    }, (error) => {
      onDataUpdate([]);
      onError(error);
    });
  }
};
