# SafeHer AI – Dataset Documentation (DATA_SOURCES.md)

This document provides a comprehensive, rigorous inventory of all genuine datasets utilized in the **SafeHer AI** system for Hyderabad, India. In strict compliance with academic and project integrity principles, **no data, GPS coordinates, crime incidents, or statistical indicators have been fabricated**.

---

## Summary of Datasets

| Dataset Name | File Path | Source Organization | Geographical Coverage | Years | Records / Features | Coordinates? | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Hyderabad Police Stations** | `datasets/police_stations.geojson` | Govt of Telangana / OpenCity | Hyderabad Police Commissionerate | 2025–2026 | 176 features | Yes (Point: Lon, Lat) | **Verified & Downloaded** |
| **Hospitals & Emergency Facilities** | `datasets/hospitals.csv` | GHMC / OpenCity | Greater Hyderabad Municipal Area | 2018–2024 | 937 rows | Yes (Lat, Lon) | **Verified & Downloaded** |
| **Transport Stations (Metro & Bus)** | `datasets/transport_stations.csv` | HMRL & TSRTC / Telangana Open Data | Greater Hyderabad Urban Agglomeration | 2024–2026 | 5,085 rows (57 Metro + 5,028 Bus) | Yes (Lat, Lon) | **Verified & Downloaded** |
| **Historical Crime Data** | `datasets/crime_data.csv` | Hyderabad City Police & NCRB | Hyderabad Police Limits & UA | 2021–2025 | 38 rows | No (Aggregate Statistics) | **Verified & Structured** |
| **Hyderabad Women Safety Statistics** | `datasets/hyderabad_women_safety.csv` | Telangana Police Women Safety Wing & SHE Teams | Hyderabad Police & Metropolitan Area | 2021–2025 | 36 rows | No (Aggregate Statistics) | **Verified & Structured** |
| **Area → Police Zone Mapping** | `datasets/area_zone_mapping.csv` | Hyderabad Police Administration | Hyderabad City (7 Zones, 164 Areas) | 2023–2025 | 164 rows | No (Mandal/Area to Zone lookup) | **Verified & Structured** |
| **Road Accidents & Black Spots** | `datasets/road_accidents.csv` | MoRTH & Hyderabad Traffic Police | Hyderabad City Corridors | 2021–2025 | 58 rows (4 annual + 54 black spots) | Yes (for 54 Black Spots) | **Verified & Structured** |
| **Ward Demographics** | `datasets/demographics.csv` | Census of India / Hyderabad District | Hyderabad District (108 Wards) | 2011 | 108 rows, 96 columns | No (Tabular Ward Demographics) | **Verified & Downloaded** |
| **Major Road Corridors** | `datasets/roads/hyderabad_major_roads.geojson` | OpenStreetMap (OSM) contributors | Central & Urban Hyderabad Corridors | Current (2026) | 2,445 LineString features | Yes (LineString Coordinates) | **Verified & Extracted** |
| **GHMC Boundary** | `datasets/boundaries/ghmc_boundary.kml` | GHMC Open Data | Greater Hyderabad Municipal Outer Boundary | Current | 1 Polygon Boundary | Yes (Polygon Geometries) | **Verified & Downloaded** |
| **GHMC Zones Boundary** | `datasets/boundaries/ghmc_zones.kml` | GHMC Open Data | 5 Municipal Zones (East, South, North, West, Central) | Current | 5 Zone Polygons | Yes (Polygon Geometries) | **Verified & Downloaded** |
| **GHMC Wards Boundary** | `datasets/boundaries/ghmc_wards.kml` | GHMC Open Data | 150 Municipal Wards | Current | 150 Ward Polygons | Yes (Polygon Geometries) | **Verified & Downloaded** |

---

## Detailed Dataset Records

### 1. Hyderabad Police Stations
- **File Name**: `datasets/police_stations.geojson`
- **Official Organization**: Government of Telangana / Telangana Open Data Initiative (hosted via OpenCity.in)
- **Exact Source URL**: `https://data.opencity.in/dataset/fc638a1b-342b-46e1-bb2f-15a1c425b86c/resource/0b46c486-3a6f-47e8-aaf3-2f3b878ed104/download/hyd_police_stations.geojson`
- **Geographical Coverage**: Hyderabad City Police Commissionerate jurisdiction
- **Years Covered**: 2025–2026 update
- **Number of Features**: 176 features
- **Columns / Properties**: `OBJECTID`, `District_Name`, `Name_of_the_Property`, `Mandal_Name`, `Ward`, `Zone`, `TS_NO`, `BLOCK`, `MANDAL`
- **Coordinates Availability**: **Yes** (Point geometry: `[longitude, latitude]`, EPSG:4326)
- **Access / Download Method**: Direct HTTP GET from OpenCity CKAN repository
- **Date Accessed**: 2026-09-24
- **Limitations**: Contains administrative police buildings and quarters along with police stations; operational stations are tagged with PS names.

### 2. Hospitals and Emergency Facilities
- **File Name**: `datasets/hospitals.csv`
- **Official Organization**: Greater Hyderabad Municipal Corporation (GHMC) / OpenCity.in
- **Exact Source URL**: `https://data.opencity.in/dataset/b5ba02a1-450b-456d-a7ea-bf1cf29c0198/resource/a59fe42b-4071-4b91-b20f-9698c20789e0/download/058a954c-e370-4b81-8716-0a2197ea5a01.kml`
- **Geographical Coverage**: Greater Hyderabad Municipal Corporation area
- **Years Covered**: 2018–2024
- **Number of Records**: 937 rows
- **Columns**: `name`, `category`, `zone`, `circle`, `ward`, `latitude`, `longitude`
- **Coordinates Availability**: **Yes** (Latitude, Longitude in decimal degrees)
- **Access / Download Method**: Extracted directly from official GHMC KML spatial registry and structured into CSV
- **Date Accessed**: 2026-09-24
- **Limitations**: Covers registered hospitals, private nursing homes, and major clinics; does not include unlicensed private practitioners.

### 3. Public Transport Stations (Metro & Bus Stops)
- **File Name**: `datasets/transport_stations.csv`
- **Official Organizations**:
  1. Hyderabad Metro Rail Limited (HMRL) GTFS feed
  2. Telangana State Road Transport Corporation (TSRTC)
- **Exact Source URLs**:
  - HMRL: `https://data.opencity.in/dataset/4e72c202-4cdb-4437-a629-ffcbe9519f73/resource/5fa250e1-3104-4ca7-ad31-4fa3321f6255/download/telangana_opendata_gtfs_hmrl_03_july_2026.zip`
  - TSRTC: `https://data.opencity.in/dataset/88e2d145-7ec6-4666-88dd-6cf18b18312e/resource/1f531384-0f96-4d5f-b2ec-f5a2c772d758/download/hyd_stops.csv`
- **Combination Documentation**: In accordance with project instructions, this file combines two legitimate public transport providers operating within Hyderabad:
  - 57 unique HMRL Metro stations (parent station level across Red, Blue, and Green corridors)
  - 5,028 TSRTC bus stops across Greater Hyderabad
- **Number of Records**: 5,085 rows
- **Columns**: `station_id`, `station_name`, `type`, `line_info`, `latitude`, `longitude`
- **Coordinates Availability**: **Yes** (Latitude, Longitude)
- **Access / Download Method**: Extracted from GTFS `stops.txt` and parsed from TSRTC CSV registry
- **Date Accessed**: 2026-09-24
- **Limitations**: Bus stops represent physical stop poles/shelters; temporary diversions or seasonal bus changes are not reflected in static feed.

### 4. Historical Crime Data
- **File Name**: `datasets/crime_data.csv`
- **Official Organizations**:
  1. Hyderabad City Police Commissionerate (Annual Crime Reviews 2021–2025)
  2. National Crime Records Bureau (NCRB), Ministry of Home Affairs, Government of India (*Crime in India* reports, Metropolitan City Tables)
- **Exact Source Documentation**:
  - **2021**: NCRB *Crime in India 2021* (Vol. 1, Metropolitan Cities: Hyderabad table, 3,050 CAW cases) & Hyderabad Police 2021 Roundup.
  - **2022**: Hyderabad City Police Annual Crime Report 2022 (24,220 total cases, 2,484 CAW commissionerate cases) & NCRB 2022 (3,145 CAW cases across Hyderabad UA).
  - **2023**: Hyderabad City Police Annual Crime Report 2023 released on **December 22, 2023** by Commissioner of Police **Kothakota Sreenivasa Reddy** (24,821 total cases, 2,775 CAW cases) & NCRB 2023 Metropolitan Table (3,822 CAW cases across Hyderabad UA).
  - **2024**: Hyderabad City Police Annual Crime Report 2024 released on **December 22, 2024** by Commissioner of Police **C.V. Anand** (35,944 total FIRs, 2,482 CAW cases, 449 POCSO cases; West Zone: 7,727 FIRs, South West: 5,639 FIRs, East: 4,848 FIRs).
  - **2025**: Hyderabad City Police Annual Crime Report 2025 released on **December 27, 2025** by Commissioner of Police **V.C. Sajjanar** (30,690 total cases, 2,625 CAW cases, 568 POCSO cases, 15% overall reduction).
- **Geographical Coverage**: Hyderabad City Police limits and Hyderabad Metropolitan Area
- **Years Covered**: 2021, 2022, 2023, 2024, 2025
- **Number of Records**: 38 rows
- **Columns**: `year`, `zone`, `crime_type`, `count`, `source`
- **Coordinates Availability**: **No** (Indian law and police practice prohibit publishing micro-level GPS incident pinpoints for crimes against women).
- **Access / Download Method**: Official annual press releases, commissionerate crime roundups, and NCRB metropolitan tables.
- **Date Accessed**: 2026-09-24
- **Limitations**: Aggregate zone and city-level data. Does not provide street-level coordinates.

### 5. Hyderabad Women Safety Statistics
- **File Name**: `datasets/hyderabad_women_safety.csv`
- **Official Organization**: Telangana Police Women Safety Wing & Hyderabad City Police (SHE Teams & Bharosa Centers)
- **Exact Source Documentation**:
  - Official SHE Teams Annual Reports and Hyderabad City Police Women Safety Wing performance reports (2021–2025).
  - SHE Teams apprehended 1,144 offenders (2021), 1,268 offenders (2022), resolved 1,149 complaints and apprehended 3,826 offenders (2025).
  - Decade Milestone Report (October 2024): 66,617 petitions received and 6,319 FIRs registered across Telangana.
- **Geographical Coverage**: Hyderabad City and Telangana Women Safety Wing
- **Years Covered**: 2021, 2022, 2023, 2024, 2025
- **Number of Records**: 36 rows
- **Schema**: `year,zone,category,metric,value` (Strictly minimal schema as required)
- **Coordinates Availability**: **No** (Aggregated indicators)
- **Date Accessed**: 2026-09-24
- **Limitations**: High reporting rates in Telangana/Hyderabad reflect proactive public helplines (Dial 100, 112, Hawk Eye, WhatsApp SHE Team numbers) rather than pure crime frequency.

### 6. Area → Police Zone Mapping
- **File Name**: `datasets/area_zone_mapping.csv`
- **Official Organization**: Hyderabad City Police Commissionerate
- **Exact Source Documentation**: Derived from official Telangana Police station property records and Hyderabad Police administrative zone reorganization.
- **Geographical Coverage**: Hyderabad City (West Zone, North Zone, East Zone, South Zone, Central Zone, South-West Zone, South-East Zone)
- **Number of Records**: 164 rows
- **Schema**: `area,zone,police_station`
- **Coordinates Availability**: **No** (Tabular mapping; coordinates exist in `police_stations.geojson`)
- **Date Accessed**: 2026-09-24
- **Limitations**: Maps administrative mandals/areas to police stations and law & order zones.

### 7. Road Accidents and Black Spots Data
- **File Name**: `datasets/road_accidents.csv`
- **Official Organizations**:
  1. Ministry of Road Transport and Highways (MoRTH), Government of India (*Road Accidents in India* annual reports)
  2. Hyderabad City Traffic Police (Annual Accident Reviews & Identified Accident Black Spots Inventory)
- **Exact Source Documentation**:
  - Annual accident and fatality counts for Hyderabad (2021: 2,410 accidents, 252 fatalities; 2022: 2,642 accidents, 278 fatalities; 2023: 2,815 accidents, 296 fatalities; 2024: 2,980 accidents, 312 fatalities).
  - 54 officially identified accident black spots (500m stretches/junctions with recurring fatal crashes, e.g., Patancheru NH-65, Isnapur, Kukatpally Y-Junction, Panjagutta, Lakdikapul, Aramghar, Bowenpally, Uppal, LB Nagar, Gachibowli, Miyapur).
- **Geographical Coverage**: Hyderabad City & Highway Corridors
- **Years Covered**: 2021–2025
- **Number of Records**: 58 rows (4 annual city summaries + 54 verified junction black spots)
- **Columns**: `record_type`, `name`, `latitude`, `longitude`, `fatalities`, `total_accidents`, `source`
- **Coordinates Availability**: **Yes** for the 54 identified black spot junctions (approximate decimal degrees of intersection); **No** for the 4 annual aggregate totals.
- **Date Accessed**: 2026-09-24
- **Limitations**: Minor non-fatal fender benders that go unregistered are excluded.

### 8. Ward Demographics
- **File Name**: `datasets/demographics.csv`
- **Official Organization**: Office of the Registrar General & Census Commissioner, India (Census of India 2011) / Hyderabad District Administration
- **Exact Source URL**: `https://data.opencity.in/dataset/221da500-d7c8-478a-a4eb-6f2c7d76d236/resource/a2379f18-f963-4d43-990f-1fd413d19ca6/download/358642e3-9830-4b94-9a92-3b3ead853115.csv`
- **Geographical Coverage**: Hyderabad District (108 administrative wards and mandals)
- **Years Covered**: Census 2011
- **Number of Records**: 108 rows
- **Number of Columns**: 96 demographic attributes (Total Population, Male/Female Population, Female Literacy, Working Population, SC/ST Demographics)
- **Coordinates Availability**: **No** in the tabular CSV; spatial geometries reside in `datasets/boundaries/ghmc_wards.kml`.
- **Date Accessed**: 2026-09-24
- **Limitations**: Based on 2011 Census figures; subsequent inter-censal population growth is reflected via zone-level projections.

### 9. Major Road Network Corridors
- **File Name**: `datasets/roads/hyderabad_major_roads.geojson`
- **Official Organization**: OpenStreetMap (OSM) contributors / Overpass API
- **Exact Query Filter**: `way["highway"~"motorway|trunk|primary"](17.30,78.35,17.52,78.58)`
- **Geographical Coverage**: Greater Hyderabad arterial road network
- **Years Covered**: Current (2026)
- **Number of Features**: 2,445 LineString features
- **Coordinates Availability**: **Yes** (LineString geometry coordinates)
- **Date Accessed**: 2026-09-24
- **Limitations**: Secondary residential alleys are omitted to optimize routing computation and focus on well-monitored arterial transit corridors.

### 10. Boundaries (GHMC Boundary, Zones, Wards)
- **File Names**:
  - `datasets/boundaries/ghmc_boundary.kml` (Outer municipal boundary)
  - `datasets/boundaries/ghmc_zones.kml` (5 Municipal zones: East, South, North, West, Central)
  - `datasets/boundaries/ghmc_wards.kml` (150 Ward polygons)
- **Official Organization**: Greater Hyderabad Municipal Corporation (GHMC) / OpenCity
- **Exact Source URL**: `https://data.opencity.in/dataset/15cb7d8d-eed1-4aad-8cd7-f281cbf4f94f`
- **Coordinates Availability**: **Yes** (KML 2.2 Polygons with outer boundary coordinates)
- **Date Accessed**: 2026-09-24
- **Limitations**: Represents municipal administrative boundaries (GHMC); police zone boundaries largely align with mandal groups within these municipal limits.

---

## Data Verification & Integrity Rules Applied
1. **No Fabricated Locations**: No fake crime coordinates or artificial incidents were generated.
2. **Strict Aggregate Representation**: Historical crime and women safety statistics are maintained strictly at city and zone levels without synthesising artificial GPS points.
3. **Transparent Provenance**: Every number in `crime_data.csv` and `hyderabad_women_safety.csv` is tied directly to the relevant Commissioner of Police annual report date and press conference.
