import urllib.request
import json

def test_live_journey():
    # 1. Health check
    res = urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=15)
    print("1. Health Check:", res.read().decode())

    # 2. Start Journey
    start_payload = {
        "user_id": "usr_test_verification",
        "origin": {"address": "Secunderabad Station", "lat": 17.4334, "lon": 78.5045},
        "destination": {"address": "Charminar", "lat": 17.3616, "lon": 78.4747},
        "selected_route_id": "route_sec_char",
        "route_summary": "Via MG Road",
        "distance_km": 8.5,
        "duration_min": 22.0,
        "safety_score": 81.4,
        "safety_tier": "Safe Corridor",
        "is_recommended_safer": True
    }
    req = urllib.request.Request(
        'http://127.0.0.1:8000/api/v1/journey/start',
        data=json.dumps(start_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    start_res = json.loads(urllib.request.urlopen(req, timeout=15).read().decode())
    print("2. Start Journey:", start_res)
    journey_id = start_res["journey_id"]
    assert journey_id.startswith("jrn_")

    # 3. SOS Event during active journey
    event_payload = {
        "journey_id": journey_id,
        "event_type": "sos_trigger",
        "latitude": 17.4000,
        "longitude": 78.4800,
        "details": {"alert": "Emergency assistance requested"}
    }
    req = urllib.request.Request(
        'http://127.0.0.1:8000/api/v1/journey/event',
        data=json.dumps(event_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    event_res = json.loads(urllib.request.urlopen(req, timeout=15).read().decode())
    print("3. SOS Event Recorded:", event_res)
    assert event_res["status"] == "recorded"

    # 4. Complete Journey with User Feedback
    complete_payload = {
        "journey_id": journey_id,
        "completed_status": "completed",
        "route_experience": "Comfortable",
        "issues_noticed": ["Poor lighting"],
        "comments": "Safe journey overall, streetlights near bridge could be brighter."
    }
    req = urllib.request.Request(
        'http://127.0.0.1:8000/api/v1/journey/complete',
        data=json.dumps(complete_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    comp_res = json.loads(urllib.request.urlopen(req, timeout=15).read().decode())
    print("4. Complete Journey & Feedback:", comp_res)
    assert comp_res["feedback_saved"] is True

    # 5. Feedback Dataset Inspection
    fb_res = json.loads(urllib.request.urlopen('http://127.0.0.1:8000/api/v1/journey/feedback', timeout=15).read().decode())
    print(f"5. Stored Feedback Records: {fb_res['total_records']}")
    assert fb_res["total_records"] >= 1
    print("\n>>> LIVE JOURNEY LIFECYCLE VERIFIED SUCCESSFULLY! <<<")

if __name__ == "__main__":
    test_live_journey()
