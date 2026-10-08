"""
SafeHer AI - Emergency Amenities & Safe Spots Service
=====================================================
Queries the loaded genuine Hyderabad datasets to locate closest
police stations, hospitals, public transit hubs, and identified black spots
relative to any user GPS coordinate.
"""

from typing import List
from ..core.config import EMERGENCY_HELPLINES
from ..ml.spatial_features import haversine_km
from ..schemas.amenity import AmenityItem, NearbySafeSpotsResponse
from ..schemas.route import CoordinatePoint
from .route_service import RouteSafetyService


class AmenitiesService:
    """Provides spatial queries for emergency civic infrastructure."""

    @classmethod
    def get_nearby_safe_spots(
        cls, latitude: float, longitude: float, radius_km: float = 5.0, limit_per_category: int = 5
    ) -> NearbySafeSpotsResponse:
        """
        Locates the closest police stations, emergency hospitals, transit hubs,
        and accident black spots for a given coordinate.
        """
        scorer = RouteSafetyService.get_scorer()
        loader = scorer.loader

        # 1. Police Stations
        police_items = []
        for idx, ps in enumerate(loader.police_stations):
            dist = haversine_km(latitude, longitude, ps["lat"], ps["lon"])
            if dist <= radius_km:
                police_items.append(
                    AmenityItem(
                        id=f"ps_{idx}",
                        name=ps["name"],
                        category="Police Station",
                        distance_km=round(dist, 2),
                        latitude=ps["lat"],
                        longitude=ps["lon"],
                        phone="100 / 040-27852435",
                        zone_or_circle=ps.get("zone", "Hyderabad Police"),
                        extra_details="24/7 Law Enforcement & SHE Team Desk",
                    )
                )
        police_items.sort(key=lambda x: x.distance_km)
        police_items = police_items[:limit_per_category]

        # 2. Emergency Hospitals
        hospital_items = []
        for idx, h in enumerate(loader.hospitals):
            dist = haversine_km(latitude, longitude, h["lat"], h["lon"])
            if dist <= radius_km:
                hospital_items.append(
                    AmenityItem(
                        id=f"hosp_{idx}",
                        name=h["name"],
                        category="Emergency Hospital",
                        distance_km=round(dist, 2),
                        latitude=h["lat"],
                        longitude=h["lon"],
                        phone="108",
                        zone_or_circle=h.get("zone", "GHMC Area"),
                        extra_details="Emergency & Trauma Medical Facility",
                    )
                )
        hospital_items.sort(key=lambda x: x.distance_km)
        hospital_items = hospital_items[:limit_per_category]

        # 3. Transit Stations (Metro & TSRTC)
        transit_items = []
        for idx, t in enumerate(loader.transit_stops):
            dist = haversine_km(latitude, longitude, t["lat"], t["lon"])
            if dist <= radius_km:
                transit_items.append(
                    AmenityItem(
                        id=f"tr_{idx}",
                        name=t["name"],
                        category=t.get("type", "Transit Station"),
                        distance_km=round(dist, 2),
                        latitude=t["lat"],
                        longitude=t["lon"],
                        phone="040-23332555" if "Metro" in t.get("type", "") else "040-69440000",
                        zone_or_circle="HMRL / TSRTC",
                        extra_details="Public Transit Hub with CCTV & Lighting",
                    )
                )
        transit_items.sort(key=lambda x: x.distance_km)
        transit_items = transit_items[:limit_per_category]

        # 4. Accident Black Spots (Traffic Hazard Warning)
        blackspot_items = []
        for idx, bs in enumerate(loader.black_spots):
            dist = haversine_km(latitude, longitude, bs["lat"], bs["lon"])
            if dist <= radius_km:
                blackspot_items.append(
                    AmenityItem(
                        id=f"bs_{idx}",
                        name=bs["name"],
                        category="Accident Black Spot",
                        distance_km=round(dist, 2),
                        latitude=bs["lat"],
                        longitude=bs["lon"],
                        phone="100 / Traffic Police",
                        zone_or_circle=bs.get("source", "Hyderabad Traffic Police"),
                        extra_details="Identified recurring vehicular crash junction. Exercise heightened vigilance.",
                    )
                )
        blackspot_items.sort(key=lambda x: x.distance_km)
        blackspot_items = blackspot_items[:limit_per_category]

        return NearbySafeSpotsResponse(
            user_location=CoordinatePoint(latitude=latitude, longitude=longitude),
            radius_km=radius_km,
            police_stations=police_items,
            hospitals=hospital_items,
            transit_stations=transit_items,
            accident_blackspots=blackspot_items,
            emergency_helplines=EMERGENCY_HELPLINES,
        )
