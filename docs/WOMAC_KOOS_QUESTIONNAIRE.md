# WOMAC & KOOS Clinical Questionnaire Reference Guide

## Overview

The **WOMAC** (*Western Ontario and McMaster Universities Osteoarthritis Index*) and **KOOS** (*Knee Injury and Osteoarthritis Outcome Score*) are standardized clinical assessment instruments designed to evaluate symptom severity, pain, stiffness, and physical disability in individuals with knee osteoarthritis (OA).

In **CREPISENSE**, the standard 24-item WOMAC questionnaire is used in Tier 1 screening to compute symptom severity scores that feed into the Machine Learning OA Risk Classifier alongside phone accelerometer mobility metrics.

---

## 1. Response Scale & Scoring System

Every question is scored on a 5-point Likert scale (0 to 4):

| **Score** | **Clinical Severity Level** | **Description** |
| :---: | :--- | :--- |
| **0** | **None** | No pain, stiffness, or difficulty experienced |
| **1** | **Mild** | Slight symptom presence, minimal interference |
| **2** | **Moderate** | Noticeable discomfort or limitation |
| **3** | **Severe** | Substantial impairment during activity |
| **4** | **Extreme** | Inability or severe pain preventing activity |

> [!NOTE]
> **Clinical Note on Activity Overlap:**
> Certain activities (such as *walking on flat surfaces*, *stairs*, *sitting*, or *lying in bed*) appear in both the **Pain** and **Physical Function** subscales. This is intentional in the standardized WOMAC index:
> - **Pain Subscale** assesses *nociceptive pain intensity* experienced during the activity.
> - **Function Subscale** assesses *degree of disability/difficulty* (e.g., stiffness, instability, weakness, reduced range of motion) experienced during the activity.


---

## 2. Questionnaire Domains & Items

The questionnaire consists of **24 questions** divided across 3 primary clinical subscales:

```
Total WOMAC Items (24)
├── Pain Subscale (5 Items) ────────► Score Range: 0 – 20
├── Stiffness Subscale (2 Items) ──► Score Range: 0 – 8
└── Physical Function (17 Items) ──► Score Range: 0 – 68
                                    ────────────────────
                                    Total Score: 0 – 96
```

---

### A. Pain Subscale (5 Items)
*Assesses pain severity during specific weight-bearing and non-weight-bearing activities.*

| ID | Item Title | Description / Question Prompt | Score Range |
| :---: | :--- | :--- | :---: |
| **P1** | Walking on Flat Surface | Pain experienced while walking on flat ground | `0 – 4` |
| **P2** | Going Up / Down Stairs | Pain experienced when walking up or down stairs | `0 – 4` |
| **P3** | At Night in Bed | Pain experienced at night while lying in bed | `0 – 4` |
| **P4** | Sitting or Lying Down | Pain experienced while sitting or lying down | `0 – 4` |
| **P5** | Standing Upright | Pain experienced while standing upright | `0 – 4` |

* **Pain Subscale Total:** `P1 + P2 + P3 + P4 + P5` (Max: **20 points**)

---

### B. Stiffness Subscale (2 Items)
*Assesses joint stiffness and restriction of movement.*

| ID | Item Title | Description / Question Prompt | Score Range |
| :---: | :--- | :--- | :---: |
| **S1** | Morning Stiffness | Severity of joint stiffness immediately after waking | `0 – 4` |
| **S2** | Resting Stiffness | Severity of stiffness after sitting, lying, or resting later in the day | `0 – 4` |

* **Stiffness Subscale Total:** `S1 + S2` (Max: **8 points**)

---

### C. Physical Function Subscale (17 Items)
*Assesses degree of difficulty experienced during daily physical activities.*

| ID | Item Title | Description / Question Prompt | Score Range |
| :---: | :--- | :--- | :---: |
| **F1** | Descending Stairs | Difficulty descending stairs | `0 – 4` |
| **F2** | Ascending Stairs | Difficulty ascending stairs | `0 – 4` |
| **F3** | Rising from Sitting | Difficulty rising from a sitting position | `0 – 4` |
| **F4** | Standing | Difficulty standing upright for extended periods | `0 – 4` |
| **F5** | Bending to Floor | Difficulty bending down to pick up an object from the floor | `0 – 4` |
| **F6** | Walking on Flat Surface | Difficulty walking on flat surfaces | `0 – 4` |
| **F7** | Getting In / Out of Car | Difficulty getting in or out of a vehicle | `0 – 4` |
| **F8** | Going Shopping | Difficulty going out for shopping | `0 – 4` |
| **F9** | Putting On Socks | Difficulty putting on socks, stockings, or shoes | `0 – 4` |
| **F10** | Rising from Bed | Difficulty getting out of bed in the morning | `0 – 4` |
| **F11** | Taking Off Socks | Difficulty taking off socks or stockings | `0 – 4` |
| **F12** | Lying in Bed | Difficulty lying comfortably in bed | `0 – 4` |
| **F13** | Getting In / Out of Bath | Difficulty getting into or out of a bath / shower | `0 – 4` |
| **F14** | Sitting | Difficulty sitting comfortably for extended periods | `0 – 4` |
| **F15** | Getting On / Off Toilet | Difficulty getting on or off the toilet | `0 – 4` |
| **F16** | Heavy Domestic Duties | Difficulty with heavy household work (scrubbing floors, lifting heavy items) | `0 – 4` |
| **F17** | Light Domestic Duties | Difficulty with light household work (cooking, dusting, sweeping) | `0 – 4` |

* **Physical Function Subscale Total:** `F1 + F2 + ... + F17` (Max: **68 points**)

---

## 3. Total Score Calculation & Clinical Interpretation

$$\text{Total WOMAC Score} = \text{Pain Score (0–20)} + \text{Stiffness Score (0–8)} + \text{Function Score (0–68)}$$

* **Maximum Raw Score:** `96 points`
* **Percentage Severity Index:** $(\text{Total Score} / 96) \times 100\%$

### Severity Categorization Matrix

| Total Score (0–96) | WOMAC % Index | Clinical Severity Category | Associated Risk Target |
| :---: | :---: | :--- | :--- |
| **0 – 15** | `0.0% – 15.6%` | **Minimal / Asymptomatic** | Low Risk (KL Grade 0–1) |
| **16 – 35** | `16.7% – 36.5%` | **Mild Osteoarthritis Symptoms** | Low–Moderate Risk (KL Grade 1–2) |
| **36 – 60** | `37.5% – 62.5%` | **Moderate Osteoarthritis** | Moderate–High Risk (KL Grade 2–3) |
| **61 – 96** | `63.5% – 100%` | **Severe Osteoarthritis** | High Risk (KL Grade 3–4) |

---

## 4. Integration in CREPISENSE ML Pipeline

In the CREPISENSE mobile application ([`QuestionnaireResponse`](file:///d:/sih-oa-screening/mobile_app/lib/models/questionnaire_response.dart)), the 24 items are recorded offline, and the computed totals (`womac_pain`, `womac_stiffness`, `womac_function`) are normalized alongside phone accelerometer sensor metrics (`peak_accel`, `accel_variance`, `cadence_cps`, `kinetic_energy`) to predict Kellgren-Lawrence (KL) Grade and Risk Level.
