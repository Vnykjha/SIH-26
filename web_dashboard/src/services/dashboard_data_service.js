import { db } from "./firebase_config";
import { 
  collection, 
  getDocs, 
  query, 
  orderBy, 
  limit, 
  onSnapshot 
} from "firebase/firestore";

/**
 * CREPISENSE Dashboard Data Service
 * Provides data fetch abstractions and real-time listeners for district & MDoNER dashboard analytics.
 */
export const DashboardDataService = {
  /**
   * Fetches overall aggregate screening statistics.
   */
  async fetchScreeningMetrics() {
    try {
      const colRef = collection(db, "screenings");
      const snapshot = await getDocs(colRef);

      let totalCount = 0;
      let lowCount = 0;
      let medCount = 0;
      let highCount = 0;
      let sumWomac = 0;
      let sumAge = 0;

      snapshot.forEach((doc) => {
        const data = doc.data();
        totalCount++;

        const risk = (data.risk_level || "low").toLowerCase();
        if (risk === "high") highCount++;
        else if (risk === "medium" || risk === "med") medCount++;
        else lowCount++;

        sumWomac += (data.total_womac_score || 0);
        sumAge += (data.age || 0);
      });

      return {
        totalScreenings: totalCount,
        lowRiskCount: lowCount,
        mediumRiskCount: medCount,
        highRiskCount: highCount,
        avgWomacScore: totalCount > 0 ? (sumWomac / totalCount).toFixed(1) : 0,
        avgPatientAge: totalCount > 0 ? (sumAge / totalCount).toFixed(1) : 0,
      };
    } catch (error) {
      console.error("Error fetching screening metrics:", error);
      return {
        totalScreenings: 0,
        lowRiskCount: 0,
        mediumRiskCount: 0,
        highRiskCount: 0,
        avgWomacScore: 0,
        avgPatientAge: 0,
      };
    }
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
        const data = doc.data();
        const district = data.district || "Unassigned District";
        const risk = (data.risk_level || "low").toLowerCase();

        if (!districtMap[district]) {
          districtMap[district] = { district, low: 0, medium: 0, high: 0, total: 0 };
        }

        districtMap[district].total++;
        if (risk === "high") districtMap[district].high++;
        else if (risk === "medium" || risk === "med") districtMap[district].medium++;
        else districtMap[district].low++;
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
  subscribeToRealtimeScreenings(onDataUpdate, maxRecords = 50) {
    const q = query(
      collection(db, "screenings"),
      orderBy("created_at", "desc"),
      limit(maxRecords)
    );

    return onSnapshot(q, (snapshot) => {
      const screenings = [];
      snapshot.forEach((doc) => {
        screenings.push({ id: doc.id, ...doc.data() });
      });
      onDataUpdate(screenings);
    });
  }
};
