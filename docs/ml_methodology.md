# SafeHer AI – Machine Learning & Safety Scoring Methodology

This document outlines the analytical architecture, spatial feature engineering, mathematical normalization, scoring logic, and research limitations of the **SafeHer AI** route safety-scoring engine for Hyderabad, India.

---

## 1. Problem Definition
When a user requests navigation between an origin and destination, navigation systems typically prioritize the quickest or shortest path. However, for women and vulnerable travelers, factors such as proximity to emergency facilities, presence of public transit, avoidance of high-risk accident junctions, and avoiding dark, isolated detours are critical.

SafeHer AI evaluates alternative route polylines obtained from the Google Directions API and computes a **Comparative Safety Score (0.0 to 100.0)** to identify a **comparatively safer route**. 

> [!IMPORTANT]
> The system **does not guarantee absolute safety** or claim that any corridor is "100% safe." The output represents an analytical comparative ranking based on verified empirical data.

---

## 2. Available Genuine Datasets
The scoring engine operates directly on verified spatial and statistical datasets loaded from `datasets/`:
1. `police_stations.geojson` (176 points): Operational police stations, zones, and mandals from Telangana Open Data.
2. `hospitals.csv` (937 points): Hospitals and healthcare facilities from GHMC Open Data.
3. `transport_stations.csv` (5,085 points): 57 Hyderabad Metro Rail stations and 5,028 TSRTC bus stops.
4. `road_accidents.csv` (58 rows): 54 officially identified accident black spots with junction coordinates and annual city totals.
5. `roads/hyderabad_major_roads.geojson` (2,445 lines): Primary, trunk, and motorway road segments from OpenStreetMap.
6. `crime_data.csv` (38 rows): Official Hyderabad City Police annual crime reviews (2021–2025) and NCRB metropolitan tables.
7. `hyderabad_women_safety.csv` (36 rows): Telangana Police Women Safety Wing and SHE Teams statistics.

---

## 3. Data Limitations & Research Integrity
- **No Micro-Level Crime Incident Points**: Indian law and police reporting standards strictly prohibit publishing micro-level GPS coordinates of crimes against women. Official crime data is published aggregated by police zone and city level.
- **No Fake Crime Points**: SafeHer AI does **not** synthesize or fabricate point-level crime locations.
- **Non-Equivalence of Raw Volume vs Population Risk**: Census ward populations (2011) do not map one-to-one to the 2023 7-zone police commissionerate boundaries. Therefore, the system utilizes relative reported FIR volume across the 7 police zones, rather than claiming to calculate unverified per-capita crime rates.

---

## 4. Feature Engineering
Each candidate route polyline is sampled at 100-meter spatial intervals ($S = \{p_1, p_2, \dots, p_n\}$). Seven distinct raw features are extracted:

1. **`avg_police_dist_km`**: Mean great-circle distance (km) from route samples to the closest operational police station.
2. **`police_within_1km_count`**: Count of unique police stations located within 1 km of the route path.
3. **`min_hospital_dist_km`**: Shortest distance (km) from any route sample to a registered emergency medical facility.
4. **`transit_count`**: Count of metro stations and bus stops situated within a 500m corridor buffer.
5. **`arterial_len_km`**: Length of the route (km) traversing designated primary, trunk, or motorway corridors.
6. **`weighted_crime_risk`**: Distance-weighted average of relative reported crime risk across traversed police zones.
7. **`blackspot_count`**: Number of identified traffic accident black spots located within 250m of the route.
8. **`detour_ratio`**: Ratio of actual route road distance to straight-line Euclidean distance: $R_{\text{detour}} = \frac{D_{\text{route}}}{D_{\text{straight}}}$.

---

## 5. Geographic Processing Logic
All spatial relationships are computed using spherical trigonometry (Haversine formula):
- **Polyline Sampling**: A linear interpolation algorithm samples points every 100 meters along route segments.
- **Buffer Queries**: Euclidean/Haversine distance filters determine points of interest within designated buffers (1 km for police, 500m for transit, 250m for black spots).
- **Zone Association**: Each route sample point is associated with the zone of its nearest police station, creating a Voronoi spatial partition that maps the route directly to the 7 Hyderabad police zones without requiring heavy external GIS software.

---

## 6. Safety Factors & Contextual Proxies
The components are categorized into three distinct analytical groups:
1. **Direct Emergency Infrastructure**:
   - `S_police`: Proximity and density of law enforcement facilities.
   - `S_medical`: Proximity to emergency trauma care and hospitals.
2. **Contextual Infrastructure Proxies**:
   - `S_transit`: Contextual proxy for public transit infrastructure and potential bystander presence. *(Not a direct guarantee of personal safety; transit hubs can experience petty crime).*
   - `S_arterial`: Contextual proxy for road network hierarchy. *(Major roads carry higher vehicular traffic, but this does not guarantee functional street lighting on any given night).*
3. **Penalties & Hazards**:
   - `P_crime`: Jurisdictional crime volume penalty based on official police annual reports.
   - `P_blackspot`: Traffic collision hazard penalty at known high-fatality junctions. *(Kept distinct from personal-security crime risk).*
   - `P_exposure`: Penalty for indirect, winding detours that prolong nighttime travel.

---

## 7. Scoring Methodology & Mathematical Formulation

### Logical Component Order:
$$S_{\text{police}} \rightarrow S_{\text{medical}} \rightarrow S_{\text{transit}} \rightarrow S_{\text{arterial}} \rightarrow P_{\text{crime}} \rightarrow P_{\text{blackspot}} \rightarrow P_{\text{exposure}}$$

### Component Normalization Equations:
1. **Police Accessibility**:
   $$S_{\text{police}} = 0.70 \times \max\left(0.0, 1.0 - \frac{d_{\text{police, avg}}}{4.0}\right) + 0.30 \times \min\left(1.0, \frac{n_{\text{police, 1km}}}{3}\right)$$
2. **Emergency Medical Access**:
   $$S_{\text{medical}} = \max\left(0.0, 1.0 - \frac{d_{\text{hosp, min}}}{3.0}\right)$$
3. **Transit Presence Proxy**:
   $$S_{\text{transit}} = \min\left(1.0, \frac{\rho_{\text{transit}}}{6.0}\right), \quad \text{where } \rho_{\text{transit}} = \frac{n_{\text{transit}}}{L_{\text{route}}}$$
4. **Arterial Road Hierarchy Proxy**:
   $$S_{\text{arterial}} = \frac{L_{\text{arterial}}}{L_{\text{route}}}$$
5. **Jurisdictional Crime Volume Penalty**:
   $$P_{\text{crime}} = \sum_{z \in \text{traversed}} \left( \frac{C_z - 4,310}{3,417} \times \frac{L_z}{L_{\text{route}}} \right)$$
6. **Traffic Accident Black Spot Penalty**:
   $$P_{\text{blackspot}} = \min\left(1.0, n_{\text{blackspot}} \times 0.50\right)$$
7. **Route Detour & Exposure Penalty**:
   $$P_{\text{exposure}} = \min\left(1.0, \max\left(0.0, \frac{R_{\text{detour}} - 1.25}{1.00}\right)\right)$$

### Project-Defined Analytical Weights:
- $w_{\text{police}} = 0.25$ (25%)
- $w_{\text{medical}} = 0.15$ (15%)
- $w_{\text{transit}} = 0.15$ (15%)
- $w_{\text{arterial}} = 0.15$ (15%)
- $w_{\text{crime}} = 0.15$ (15%)
- $w_{\text{blackspot}} = 0.10$ (10%)
- $w_{\text{exposure}} = 0.05$ (5%)
- **Total**: $\sum w = 1.000$

### Unified Score Equation:
$$\text{Safety Score} = 100 \times \Big( 0.25 S_{\text{police}} + 0.15 S_{\text{medical}} + 0.15 S_{\text{transit}} + 0.15 S_{\text{arterial}} + 0.15 (1 - P_{\text{crime}}) + 0.10 (1 - P_{\text{blackspot}}) + 0.05 (1 - P_{\text{exposure}}) \Big)$$

Bounded strictly to $[0.0, 100.0]$ via mathematical clamping:
$$\text{Safety Score} = \min\left(100.0, \max\left(0.0, \text{round}(\text{Score}, 1)\right)\right)$$

### Qualitative Comparative Tiers:
- **$\text{Score} \ge 75.0$**: *Comparatively Safer Route*
- **$50.0 \le \text{Score} < 75.0$**: *Moderate Safety Corridor*
- **$\text{Score} < 50.0$**: *Caution Advised Corridor*

---

## 8. Why Supervised Machine Learning is NOT Justified
1. **No Ground Truth Labels**: Neither the police, municipal corporations, nor research organizations publish labeled datasets of real-world routes marked as "Safe" or "Unsafe."
2. **Avoidance of Pseudo-Supervised Learning**: Assigning synthetic binary labels to routes based on an arbitrary formula and training a classifier to predict those labels is circular and introduces artificial modeling error.
3. **Explainability**: A multi-criteria spatial scoring engine provides 100% transparent, auditable reasoning for why one corridor scored higher than another during academic defense.

---

## 9. Role of Unsupervised Machine Learning
Unsupervised machine learning (e.g., K-Means clustering) can be used as an auxiliary exploratory tool to group corridors into structural profiles based on physical infrastructure features. It does **not** predict ground-truth safety, and clusters are never labeled as "safe" or "unsafe" without documented contextual caveats.

---

## 10. Summary of Architectural Verification
The scoring engine has been implemented in `backend/app/ml/` and verified with 14 unit tests in `backend/tests/test_safety_scoring.py`:
- Pure mathematical functions verify exact boundary limits ($0.0$ minimum, $100.0$ maximum).
- Spatial extractors dynamically read genuine GeoJSON and CSV datasets from disk.
- All calculations are fully commented and auditable.
