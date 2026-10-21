import React, { useEffect, useMemo, useState } from "react";
import { Bar, Doughnut } from "react-chartjs-2";
import { ArcElement, BarElement, CategoryScale, Chart as ChartJS, Legend, LinearScale, Tooltip } from "chart.js";
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { DashboardDataService } from "./services/dashboard_data_service";
import { auth, db, isFirebaseConfigured } from "./services/firebase_config";
import { getScreeningLocation, NER_STATES } from "./services/location_utils";

ChartJS.register(ArcElement, BarElement, CategoryScale, LinearScale, Tooltip, Legend);

const riskMeta = {
  low: { label: "Low risk", color: "#2e7d62" },
  medium: { label: "Medium risk", color: "#d18b3f" },
  high: { label: "High risk", color: "#bd4b48" }
};

function formatDate(value) {
  return new Intl.DateTimeFormat("en-IN", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }).format(new Date(value));
}

function normalizeRisk(value) {
  const risk = String(value || "low").toLowerCase();
  return risk === "med" ? "medium" : risk;
}

function App() {
  const [screenings, setScreenings] = useState([]);
  const [stateFilter, setStateFilter] = useState("All states");
  const [districtFilter, setDistrictFilter] = useState("all");
  const [riskFilter, setRiskFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [isDemo, setIsDemo] = useState(false);
  const [connectionError, setConnectionError] = useState("");
  const [authUser, setAuthUser] = useState(null);
  const [authChecking, setAuthChecking] = useState(isFirebaseConfigured);
  const [authLoading, setAuthLoading] = useState(false);
  const [authError, setAuthError] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    if (!isFirebaseConfigured) {
      setAuthChecking(false);
      return undefined;
    }

    let active = true;
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!active) return;
      setAuthUser(user);
      setIsAdmin(false);
      setAuthChecking(Boolean(user));

      if (!user) {
        setAuthChecking(false);
        return;
      }

      try {
        const admin = await getDoc(doc(db, "admins", user.uid));
        if (!active) return;
        if (admin.exists() && admin.data().role === "admin") {
          setIsAdmin(true);
          setAuthError("");
        } else {
          setAuthError("This account is not authorized as a dashboard admin.");
          await signOut(auth);
        }
      } catch (error) {
        if (active) {
          setAuthError(error.message || "Unable to verify dashboard access.");
        }
      } finally {
        if (active) setAuthChecking(false);
      }
    });

    return () => {
      active = false;
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (isFirebaseConfigured && !isAdmin) {
      setScreenings([]);
      setIsDemo(false);
      setLoading(false);
      return undefined;
    }

    const updateScreenings = (data) => {
      setScreenings(data.map((item) => ({
        ...item,
        ...getScreeningLocation(item)
      })).sort((a, b) => new Date(b.created_at) - new Date(a.created_at)));
      setIsDemo(data.some((item) => item.id?.startsWith("demo-")));
      setConnectionError("");
      setLoading(false);
    };
    const unsubscribe = DashboardDataService.subscribeToRealtimeScreenings(
      updateScreenings,
      50,
      (error) => {
        setConnectionError(error.message || "Firestore request failed.");
        setLoading(false);
      }
    );
    return unsubscribe;
  }, [isAdmin]);

  async function handleSignIn(event) {
    event.preventDefault();
    setAuthError("");
    setAuthLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (error) {
      setAuthError(error.message || "Sign-in failed.");
    } finally {
      setAuthLoading(false);
    }
  }

  const districtOptions = useMemo(() => {
    const locations = screenings.filter((item) => stateFilter === "All states" || item.state === stateFilter);
    return [...new Map(locations.map((item) => [
      item.district_filter_key,
      { key: item.district_filter_key, label: item.district }
    ])).values()].sort((a, b) => a.label.localeCompare(b.label));
  }, [screenings, stateFilter]);
  const locationFiltered = screenings.filter((item) =>
    (stateFilter === "All states" || item.state === stateFilter) &&
    (districtFilter === "all" || item.district_filter_key === districtFilter)
  );
  const filtered = locationFiltered.filter((item) =>
    riskFilter === "all" || normalizeRisk(item.risk_level) === riskFilter
  );
  const metrics = useMemo(() => {
    const total = filtered.length;
    const counts = filtered.reduce((result, item) => {
      result[normalizeRisk(item.risk_level)] = (result[normalizeRisk(item.risk_level)] || 0) + 1;
      result.womac += Number(item.total_womac_score || 0);
      result.age += Number(item.age || 0);
      return result;
    }, { low: 0, medium: 0, high: 0, womac: 0, age: 0 });
    return { ...counts, total, avgWomac: total ? (counts.womac / total).toFixed(1) : "0.0", avgAge: total ? (counts.age / total).toFixed(0) : "0" };
  }, [filtered]);
  const districtData = useMemo(() => {
    const locations = new Map();
    locationFiltered.forEach((item) => {
      const location = locations.get(item.location_key) || {
        district: item.location_label,
        total: 0,
        high: 0
      };
      location.total++;
      if (normalizeRisk(item.risk_level) === "high") location.high++;
      locations.set(item.location_key, location);
    });
    return [...locations.values()].sort((a, b) => b.total - a.total);
  }, [locationFiltered]);

  const chartOptions = { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { padding: 10, cornerRadius: 8 } }, scales: { x: { grid: { display: false }, ticks: { color: "#75807a" } }, y: { beginAtZero: true, grid: { color: "#e6e4de" }, ticks: { precision: 0, color: "#75807a" } } } };

  if (isFirebaseConfigured && authChecking) {
    return <main className="auth-page"><section className="auth-card"><strong>CREPISENSE</strong><p>Checking dashboard access…</p></section></main>;
  }

  if (isFirebaseConfigured && (!authUser || !isAdmin)) {
    return <main className="auth-page">
      <form className="auth-card" onSubmit={handleSignIn}>
        <span className="auth-mark">C</span>
        <p className="eyebrow">Restricted access</p>
        <h1>Admin sign in</h1>
        <p className="auth-description">Use an authorized Firebase admin account to view screening data.</p>
        <label htmlFor="admin-email">Email</label>
        <input id="admin-email" type="email" autoComplete="username" required value={email} onChange={(event) => setEmail(event.target.value)} />
        <label htmlFor="admin-password">Password</label>
        <input id="admin-password" type="password" autoComplete="current-password" required value={password} onChange={(event) => setPassword(event.target.value)} />
        {authError && <p className="auth-error" role="alert">{authError}</p>}
        <button className="auth-submit" type="submit" disabled={authLoading}>{authLoading ? "Signing in…" : "Sign in"}</button>
      </form>
    </main>;
  }

  return <div className="app-shell">
    <aside className="sidebar">
      <div className="brand"><span className="brand-mark">C</span><div><strong>CREPISENSE</strong><small>NER health intelligence</small></div></div>
      <nav><a className="active" href="#overview"><span>◈</span> Overview</a><a href="#screenings"><span>▤</span> Screenings</a><a href="#districts"><span>⌖</span> Districts</a></nav>
      <div className="sidebar-foot"><span className="status-dot" /> {connectionError ? "Firestore unavailable" : isDemo ? "Demo data" : loading ? "Connecting to Firestore" : "Firestore connected"}<br /><small>Read-only admin view</small></div>
    </aside>
    <main className="main-content">
      <header className="topbar"><div><p className="eyebrow">Northeast Region / Operations</p><h1>Screening overview</h1></div><div className="topbar-actions"><span className="date-chip">{authUser?.email || (isDemo ? "Demo mode" : "Admin view")}</span>{authUser && <button className="sign-out" onClick={() => signOut(auth)}>Sign out</button>}</div></header>
      {isDemo && <div className="demo-note"><span>i</span> Showing sample screening records because Firebase is not configured. Add the Vite Firebase environment variables to connect your project data.</div>}
      {connectionError && <div className="demo-note"><span>!</span> Could not read screenings from Firestore: {connectionError}</div>}
      {!loading && !connectionError && !isDemo && screenings.length === 0 && <div className="demo-note"><span>i</span> Firestore is connected, but there are no screening records yet.</div>}
      <section className="filters" aria-label="Dashboard filters"><div className="filter-label"><span className="filter-icon">☷</span><span>View filters</span></div><label>State<select value={stateFilter} onChange={(event) => { setStateFilter(event.target.value); setDistrictFilter("all"); }}><option>All states</option>{NER_STATES.map((state) => <option key={state}>{state}</option>)}</select></label><label>District<select value={districtFilter} onChange={(event) => setDistrictFilter(event.target.value)}><option value="all">All districts</option>{districtOptions.map((district) => <option key={district.key} value={district.key}>{district.label}</option>)}</select></label><label>Risk level<select value={riskFilter} onChange={(event) => setRiskFilter(event.target.value)}><option value="all">All risk levels</option><option value="high">High risk</option><option value="medium">Medium risk</option><option value="low">Low risk</option></select></label><span className="filter-result">{filtered.length} records in view</span></section>
      <section className="metric-grid"><Metric label="Total screenings" value={metrics.total} detail="Across active camps" accent="green" /><Metric label="High risk" value={metrics.high} detail={`${metrics.total ? Math.round((metrics.high / metrics.total) * 100) : 0}% of screenings`} accent="red" /><Metric label="Average WOMAC" value={metrics.avgWomac} detail="Pain + function score" accent="amber" /><Metric label="Average age" value={`${metrics.avgAge} yrs`} detail="Participant average" accent="blue" /></section>
      <section className="dashboard-grid"><article className="panel risk-panel"><div className="panel-heading"><div><p className="eyebrow">Risk profile</p><h2>Population at a glance</h2></div><span className="panel-kicker">Live snapshot</span></div><div className="risk-chart"><Doughnut data={{ labels: ["Low risk", "Medium risk", "High risk"], datasets: [{ data: [metrics.low, metrics.medium, metrics.high], backgroundColor: [riskMeta.low.color, riskMeta.medium.color, riskMeta.high.color], borderWidth: 0, hoverOffset: 5 }] }} options={{ cutout: "72%", plugins: { legend: { display: false } } }} /><div className="donut-total"><strong>{metrics.total}</strong><span>screened</span></div></div><div className="risk-legend">{["low", "medium", "high"].map((key) => <button key={key} className={`legend-row ${riskFilter === key ? "selected" : ""}`} onClick={() => setRiskFilter(riskFilter === key ? "all" : key)}><span className="legend-dot" style={{ background: riskMeta[key].color }} /><span>{riskMeta[key].label}</span><strong>{metrics[key]}</strong></button>)}</div></article><article className="panel district-panel" id="districts"><div className="panel-heading"><div><p className="eyebrow">Coverage</p><h2>District activity</h2></div><span className="panel-kicker">{districtData.length} districts</span></div><div className="bar-chart"><Bar data={{ labels: districtData.map((item) => item.district), datasets: [{ label: "Screenings", data: districtData.map((item) => item.total), backgroundColor: "#337c70", borderRadius: 4, barThickness: 18 }] }} options={chartOptions} /></div><div className="district-summary">{districtData.slice(0, 3).map((item) => <div key={item.district}><span>{item.district}</span><strong>{item.total}<small> screenings</small></strong></div>)}</div></article></section>
      <section className="panel table-panel" id="screenings"><div className="panel-heading"><div><p className="eyebrow">Latest activity</p><h2>Recent screenings</h2></div><button className="text-button" onClick={() => { setStateFilter("All states"); setDistrictFilter("all"); setRiskFilter("all"); }}>Clear filters ↗</button></div><div className="table-wrap"><table><thead><tr><th>Participant</th><th>Location</th><th>Recorded by</th><th>Risk level</th><th>Confidence</th><th>WOMAC</th><th>Screened at</th></tr></thead><tbody>{loading ? <tr><td className="empty" colSpan="7">Loading screening records…</td></tr> : filtered.slice(0, 8).map((item) => { const risk = normalizeRisk(item.risk_level); return <tr key={item.id}><td><div className="participant"><span>{String(item.name || "U").charAt(0)}</span><div><strong>{item.name || "Unnamed patient"}</strong><small>{item.sex || "Participant"} · {item.age || "—"} yrs</small></div></div></td><td><strong>{item.location_label}</strong><small className="table-sub">{item.camp_id || "Camp not listed"}</small></td><td><strong>{item.recorded_by || "Health worker"}</strong></td><td><span className={`risk-pill ${risk}`}><i />{riskMeta[risk]?.label || "Low risk"}</span></td><td>{item.confidence ? `${Math.round(Number(item.confidence) * 100)}%` : "—"}</td><td><strong>{item.total_womac_score || 0}</strong><span className="score-track"><i style={{ width: `${Math.min(Number(item.total_womac_score || 0), 100)}%` }} /></span></td><td className="muted">{formatDate(item.created_at)}</td></tr> })}</tbody></table>{!loading && !filtered.length && <div className="empty-state">{connectionError ? "Screening records could not be loaded." : "No screening records match these filters."}</div>}</div></section>
      <footer>CREPISENSE · District health operations <span>Data is read from Firestore and never from phones directly.</span></footer>
    </main>
  </div>;
}

function Metric({ label, value, detail, accent }) { return <article className={`metric-card ${accent}`}><span className="metric-icon" /><p>{label}</p><strong>{value}</strong><small>{detail}</small></article>; }

export default App;