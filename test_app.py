import pytest
from app import app


@pytest.fixture
def client():
    """Initializes a sandboxed test client instance for testing routes"""
    app.config["TESTING"] = True
    app.config["WTF_CSRF_ENABLED"] = False
    with app.test_client() as test_client:
        yield test_client


@pytest.mark.parametrize(
    "endpoint, expected_key, expected_value",
    [
        ("/api/v1.1", "version", "1.1"),
        ("/api/v1.0/health", "status", "healthy"),
        ("/api/v1.1/health", "status", "healthy"),
    ],
)
def test_status_and_health_endpoints(client, endpoint, expected_key, expected_value):
    response = client.get(endpoint)
    assert response.status_code == 200
    assert response.json[expected_key] == expected_value


def test_home_page(client):
    """Validates that the root route renders the HTML template"""
    response = client.get("/")
    assert response.status_code == 200


def test_get_programs_list(client):
    """Validates that the program tracking arrays map accurately"""
    response = client.get("/api/v1.0/programs")
    assert response.status_code == 200
    assert "Fat Loss (FL)" in response.json["programs"]


def test_entire_plan_successful_lookup(client):
    """Confirms complete plans parse and match structural string contents"""
    response = client.get("/api/v1.0/entire_plan?program_name=Muscle Gain (MG)")
    assert response.status_code == 200
    assert response.json["ui_color"] == "#2ecc71"
    assert "Chicken Biryani" in response.json["daily_nutrition_plan"]


@pytest.mark.parametrize(
    "query, expected_status, expected_msg",
    [
        ("", 400, "Missing required 'program_name'"),
        ("?program_name=Zumba", 404, "not found"),
    ],
)
def test_entire_plan_error_boundaries(client, query, expected_status, expected_msg):
    response = client.get(f"/api/v1.0/entire_plan{query}")
    assert response.status_code == expected_status
    assert expected_msg in response.json["error"]


@pytest.mark.parametrize(
    "payload, expected_calories",
    [
        ({"program": "Fat Loss (FL)", "weight": 70}, "1540 kcal"),
        ({"program": "Muscle Gain (MG)", "weight": 80}, "2800 kcal"),
        ({"program": "", "weight": 70}, "--"),
        ({"program": "Unknown", "weight": 70}, "--"),
        ({"program": "Beginner (BG)", "weight": -5}, "--"),
        ({"program": "Beginner (BG)", "weight": "invalid"}, "--"),
    ],
)
def test_calculate_calories(client, payload, expected_calories):
    response = client.post("/api/v1.1/calculate_calories", json=payload)
    assert response.status_code == 200
    assert response.json["calories"] == expected_calories


def test_save_client_success(client):
    payload = {
        "name": "Jane",
        "program": "Muscle Gain (MG)",
        "age": 25,
        "weight": 70,
        "progress": 90,
    }
    response = client.post("/api/v1.1/save_client", json=payload)
    assert response.status_code == 200
    assert "Jane" in response.json["success"]
    assert response.json["adherence"] == 90
    assert response.json["calculated_calories"] == 2450


@pytest.mark.parametrize(
    "payload, expected_status",
    [
        ({"name": "", "program": "Fat Loss (FL)"}, 400),
        ({"name": "John", "program": ""}, 400),
        ({"name": "John", "program": "Invalid Plan"}, 400),
        ({"name": "John", "program": "Fat Loss (FL)", "age": "bad_int"}, 500),
    ],
)
def test_save_client_validation_and_errors(client, payload, expected_status):
    response = client.post("/api/v1.1/save_client", json=payload)
    assert response.status_code == expected_status
    assert "error" in response.json


def test_reset_endpoint(client):
    response = client.get("/api/v1.1/reset")
    assert response.status_code == 200
    assert response.json["total_calories"] == "--"
    assert response.json["name"] == ""
