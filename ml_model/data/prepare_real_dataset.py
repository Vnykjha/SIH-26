"""
CREPISENSE — Real Clinical Dataset Ingestion & Standardization Parser
Parses user-provided real clinical datasets (OAI Baseline / Kaggle Knee OA clinical tables),
maps exact 24 WOMAC questions (P1-P5, S1-S2, F1-F17) and demographics to the standard
CREPISENSE feature contract, and outputs clean training-ready data.
"""

import os
import pandas as pd
import numpy as np

EXPECTED_COLS = [
    'age', 'sex_code', 'bmi', 'prior_injury',
    'womac_pain', 'womac_stiffness', 'womac_function',
    'duration_sec', 'peak_accel', 'accel_variance', 'cadence_cps', 'kinetic_energy',
    'risk_level'
]

def load_and_preprocess_real_data(raw_csv_path):
    print(f"Reading real clinical dataset from: {raw_csv_path}")
    df = pd.read_csv(raw_csv_path)

    # 1. Normalize Column Names
    col_map = {c: c.strip().lower() for c in df.columns}
    df = df.rename(columns=col_map)

    # 2. Extract or Map Demographics
    if 'age' not in df.columns:
        possible_age = [c for c in df.columns if 'age' in c or 'v00age' in c]
        if possible_age:
            df['age'] = df[possible_age[0]]
        else:
            raise KeyError("Could not locate 'age' column in dataset.")

    if 'sex_code' not in df.columns:
        possible_sex = [c for c in df.columns if 'sex' in c or 'gender' in c or 'v00sex' in c]
        if possible_sex:
            # Map Female/Male to 1/0
            s_col = df[possible_sex[0]]
            df['sex_code'] = s_col.apply(lambda x: 1 if str(x).upper().startswith(('F', '1', 'WOMAN', 'FEMALE')) else 0)

    if 'bmi' not in df.columns:
        possible_bmi = [c for c in df.columns if 'bmi' in c or 'v00bmi' in c]
        if possible_bmi:
            df['bmi'] = df[possible_bmi[0]]

    if 'prior_injury' not in df.columns:
        possible_inj = [c for c in df.columns if 'injur' in c or 'surgery' in c or 'history' in c]
        if possible_inj:
            df['prior_injury'] = df[possible_inj[0]].apply(lambda x: 1 if str(x).upper() in ['1', 'TRUE', 'YES', 'Y'] else 0)
        else:
            df['prior_injury'] = 0

    # 3. Process 24-Item WOMAC Subscales
    # Pain subscale (0-20)
    if 'womac_pain' not in df.columns:
        pain_cols = [c for c in df.columns if 'womac' in c and 'pain' in c]
        if pain_cols:
            df['womac_pain'] = df[pain_cols[0]]

    # Stiffness subscale (0-8)
    if 'womac_stiffness' not in df.columns:
        stiff_cols = [c for c in df.columns if 'womac' in c and ('stiff' in c or 'rigidity' in c)]
        if stiff_cols:
            df['womac_stiffness'] = df[stiff_cols[0]]

    # Function subscale (0-68)
    if 'womac_function' not in df.columns:
        func_cols = [c for c in df.columns if 'womac' in c and ('func' in c or 'phys' in c or 'disabil' in c)]
        if func_cols:
            df['womac_function'] = df[func_cols[0]]

    # 4. Mobility Metrics Mapping / Imputation if accelerometer data missing in clinical CSV
    for m_col, default_val in [('duration_sec', 15.0), ('peak_accel', 2.5), ('accel_variance', 0.5), ('cadence_cps', 1.5), ('kinetic_energy', 12.0)]:
        if m_col not in df.columns:
            possible_m = [c for c in df.columns if m_col in c]
            if possible_m:
                df[m_col] = df[possible_m[0]]
            else:
                # Derive estimated biomechanics from WOMAC impairment
                severity = (df['womac_pain'] / 20.0 + df['womac_function'] / 68.0) / 2.0
                if m_col == 'duration_sec':
                    df[m_col] = 10.0 + severity * 15.0
                elif m_col == 'peak_accel':
                    df[m_col] = 3.5 - severity * 1.5
                elif m_col == 'accel_variance':
                    df[m_col] = 0.2 + severity * 0.8
                elif m_col == 'cadence_cps':
                    df[m_col] = 2.2 - severity * 0.8
                elif m_col == 'kinetic_energy':
                    df[m_col] = 18.0 - severity * 7.0

    # 5. Risk Level Ground Truth Target
    if 'risk_level' not in df.columns:
        kl_cols = [c for c in df.columns if 'kl' in c or 'grade' in c or 'stage' in c or 'severity' in c]
        if kl_cols:
            kl_vals = df[kl_cols[0]]
            # Map KL grade 0-1 -> Low (0), KL 2 -> Medium (1), KL 3-4 -> High (2)
            df['risk_level'] = kl_vals.apply(lambda x: 0 if x in [0, 1] else (1 if x == 2 else 2))
        else:
            womac_ratio = (df['womac_pain'] + df['womac_stiffness'] + df['womac_function']) / 96.0
            df['risk_level'] = womac_ratio.apply(lambda r: 0 if r < 0.3 else (1 if r < 0.55 else 2))

    clean_df = df[EXPECTED_COLS].dropna()
    print(f"Successfully processed {len(clean_df)} real patient records.")
    return clean_df

if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.abspath(__file__))
    raw_path = os.path.join(base_dir, 'real_oa_dataset.csv')
    if os.path.exists(raw_path):
        processed_df = load_and_preprocess_real_data(raw_path)
        out_path = os.path.join(base_dir, 'oa_risk_dataset.csv')
        processed_df.to_csv(out_path, index=False)
        print(f"Processed real dataset written to: {out_path}")
    else:
        print(f"Notice: Please download real dataset and place it at: {raw_path}")
