export const NER_STATES = [
  "Arunachal Pradesh",
  "Assam",
  "Manipur",
  "Meghalaya",
  "Mizoram",
  "Nagaland",
  "Sikkim",
  "Tripura"
];

function canonicalState(value) {
  const normalized = String(value || "").trim().toLowerCase();
  return NER_STATES.find((state) => state.toLowerCase() === normalized) || "";
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function getScreeningLocation(screening) {
  const rawDistrict = String(screening.district || "").trim().replace(/\s+/g, " ");
  let districtText = rawDistrict;
  let state = canonicalState(screening.state);
  const matchedState = NER_STATES.find((candidate) =>
    new RegExp(`(?:^|[\\s,;/|-])${escapeRegExp(candidate)}$`, "i").test(rawDistrict)
  );

  if (matchedState) {
    state = state || matchedState;
    districtText = rawDistrict.toLowerCase() === matchedState.toLowerCase()
      ? ""
      : rawDistrict.replace(
        new RegExp(`(?:[\\s,;/|-]+)${escapeRegExp(matchedState)}$`, "i"),
        ""
      ).trim();
  } else if (!state) {
    state = canonicalState(rawDistrict);
    if (state) districtText = "";
  }

  const codeMatch = districtText.match(/\bdistrict\s*[-_ ]?\s*0*(\d+)\b/i);
  if (codeMatch) {
    const number = Number(codeMatch[1]);
    const code = `district:${number}`;
    const district = `District-${String(number).padStart(2, "0")}`;
    return {
      state,
      district,
      district_filter_key: code,
      location_key: `${state.toLowerCase() || "unassigned"}:${code}`,
      location_label: state ? `${state} · ${district}` : district
    };
  }

  const name = districtText || "Unassigned district";
  const districtFilterKey = `name:${name.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()}`;
  return {
    state,
    district: name,
    district_filter_key: districtFilterKey,
    location_key: `${state.toLowerCase() || "unassigned"}:${districtFilterKey}`,
    location_label: state ? `${state} · ${name}` : name
  };
}
