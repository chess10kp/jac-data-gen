# mockData.cl.jac
# Shared mock data for Nourish app — wire to Supabase later

def:pub get_mock_donations() -> list[any] {
    return [
        {
            "id": "d1",
            "title": "Fresh Vegetables Mix",
            "description": "Assorted seasonal vegetables: carrots, broccoli, spinach. Freshly harvested.",
            "category": "Vegetables",
            "quantity": "45 kg",
            "expiry_date": "2025-07-15",
            "pickup_address": "12 Market St, Downtown",
            "lat": 40.7128,
            "lng": -74.0060,
            "status": "available",
            "organization": "FreshMart Supermarket",
            "org_id": "org1",
            "created_at": "2025-07-10",
            "image": "",
            "storage_type": "Refrigerated",
            "available_from": "08:00",
            "available_until": "18:00"
        },
        {
            "id": "d2",
            "title": "Artisan Bread Loaves",
            "description": "Freshly baked sourdough and whole wheat loaves from today's batch.",
            "category": "Bread & Bakery",
            "quantity": "30 loaves",
            "expiry_date": "2025-07-12",
            "pickup_address": "45 Oak Ave, Midtown",
            "lat": 40.7200,
            "lng": -74.0100,
            "status": "available",
            "organization": "The Green Bistro",
            "org_id": "org2",
            "created_at": "2025-07-11",
            "image": "",
            "storage_type": "Room temperature",
            "available_from": "07:00",
            "available_until": "14:00"
        },
        {
            "id": "d3",
            "title": "Dairy Products Bundle",
            "description": "Milk, yogurt, and cheese approaching best-before date. Still perfectly safe.",
            "category": "Dairy",
            "quantity": "60 units",
            "expiry_date": "2025-07-13",
            "pickup_address": "88 Elm Rd, Eastside",
            "lat": 40.7050,
            "lng": -73.9950,
            "status": "available",
            "organization": "City Grocery Co.",
            "org_id": "org3",
            "created_at": "2025-07-11",
            "image": "",
            "storage_type": "Refrigerated",
            "available_from": "09:00",
            "available_until": "17:00"
        },
        {
            "id": "d4",
            "title": "Canned Goods Collection",
            "description": "Assorted canned beans, tomatoes, corn, and soups. Long shelf life.",
            "category": "Canned Goods",
            "quantity": "120 cans",
            "expiry_date": "2026-01-01",
            "pickup_address": "3 Pine Blvd, Westside",
            "lat": 40.7300,
            "lng": -74.0200,
            "status": "available",
            "organization": "Metro Food Bank",
            "org_id": "org4",
            "created_at": "2025-07-09",
            "image": "",
            "storage_type": "Dry storage",
            "available_from": "10:00",
            "available_until": "16:00"
        },
        {
            "id": "d5",
            "title": "Prepared Meal Packs",
            "description": "Hot meals: rice with chicken, vegetable stew. Ready to serve.",
            "category": "Prepared Meals",
            "quantity": "80 portions",
            "expiry_date": "2025-07-11",
            "pickup_address": "22 Cedar Lane, Central",
            "lat": 40.7150,
            "lng": -74.0080,
            "status": "expiring_soon",
            "organization": "Community Kitchen",
            "org_id": "org5",
            "created_at": "2025-07-11",
            "image": "",
            "storage_type": "Hot holding",
            "available_from": "12:00",
            "available_until": "20:00"
        }
    ];
}

def:pub get_mock_requests() -> list[any] {
    return [
        {
            "id": "r1",
            "title": "Family of 5 needs groceries",
            "description": "Single mother with 4 children. Lost job last month. Need basic food supplies.",
            "comment": "any vegetables, bread, or dairy would be greatly appreciated.",
            "people_count": 5,
            "urgency": "high",
            "food_type": "Mixed groceries",
            "location_text": "East Village, Block 4",
            "lat": 40.7250,
            "lng": -73.9900,
            "status": "open",
            "posted_by": "Maria S.",
            "user_id": "u1",
            "created_at": "2025-07-11T09:30:00"
        },
        {
            "id": "r2",
            "title": "Elderly couple - weekly food support",
            "description": "Retired couple on fixed income. Need soft foods and easy-to-prepare meals.",
            "comment": "Prefer low-sodium options due to health conditions.",
            "people_count": 2,
            "urgency": "medium",
            "food_type": "Soft foods, prepared meals",
            "location_text": "Northside, Maple Ave",
            "lat": 40.7350,
            "lng": -74.0150,
            "status": "open",
            "posted_by": "James K.",
            "user_id": "u2",
            "created_at": "2025-07-10T14:00:00"
        },
        {
            "id": "r3",
            "title": "URGENT: Shelter needs 50 meals tonight",
            "description": "Emergency overflow at Hope Shelter. 50 additional people arrived. Need immediate food.",
            "comment": "any hot meals or ready-to-eat food. Time-sensitive.",
            "people_count": 50,
            "urgency": "critical",
            "food_type": "Hot meals, any food",
            "location_text": "Hope Community Shelter, 88 Elm Rd",
            "lat": 40.7050,
            "lng": -73.9950,
            "status": "open",
            "posted_by": "Hope Shelter",
            "user_id": "u3",
            "created_at": "2025-07-11T17:00:00"
        },
        {
            "id": "r4",
            "title": "Food for refugee family",
            "description": "Recently arrived refugee family of 7. Need culturally appropriate food.",
            "comment": "Halal preferred. Rice, vegetables, legumes.",
            "people_count": 7,
            "urgency": "high",
            "food_type": "Rice, vegetables, halal",
            "location_text": "Westside Community Center",
            "lat": 40.7300,
            "lng": -74.0200,
            "status": "open",
            "posted_by": "Refugee Aid Org",
            "user_id": "u4",
            "created_at": "2025-07-11T11:00:00"
        },
        {
            "id": "r5",
            "title": "After-school snacks needed",
            "description": "Community center runs after-school program for 30 kids. Need healthy snacks.",
            "comment": "Fruits, vegetables, or packaged snacks. No nuts due to allergies.",
            "people_count": 30,
            "urgency": "low",
            "food_type": "Snacks, fruits",
            "location_text": "Sunrise Community Center",
            "lat": 40.7180,
            "lng": -74.0050,
            "status": "open",
            "posted_by": "Sunrise Center",
            "user_id": "u5",
            "created_at": "2025-07-09T10:00:00"
        }
    ];
}

def:pub get_mock_events() -> list[any] {
    return [
        {
            "id": "e1",
            "title": "Community Food Distribution Day",
            "description": "Monthly food distribution event. Free groceries for families in need. Bring ID.",
            "organizer": "Metro Food Bank",
            "org_id": "org4",
            "event_date": "2025-07-20",
            "event_time": "10:00 AM - 2:00 PM",
            "address": "Central Park Community Hall, 5th Ave",
            "lat": 40.7200,
            "lng": -74.0100,
            "food_type": "Mixed groceries",
            "capacity": 200,
            "registered": 145,
            "status": "upcoming"
        },
        {
            "id": "e2",
            "title": "Hot Meal Sunday",
            "description": "Weekly hot meal service. Soup, bread, and dessert. Everyone welcome.",
            "organizer": "Community Kitchen",
            "org_id": "org5",
            "event_date": "2025-07-13",
            "event_time": "12:00 PM - 3:00 PM",
            "address": "22 Cedar Lane, Central",
            "lat": 40.7150,
            "lng": -74.0080,
            "food_type": "Hot meals",
            "capacity": 100,
            "registered": 78,
            "status": "upcoming"
        },
        {
            "id": "e3",
            "title": "Ramadan Food Drive",
            "description": "Special food drive providing halal food packages for families during Ramadan.",
            "organizer": "Islamic Relief Network",
            "org_id": "org6",
            "event_date": "2025-07-25",
            "event_time": "4:00 PM - 8:00 PM",
            "address": "Westside Mosque, 3 Pine Blvd",
            "lat": 40.7300,
            "lng": -74.0200,
            "food_type": "Halal food packages",
            "capacity": 150,
            "registered": 92,
            "status": "upcoming"
        }
    ];
}

def:pub get_mock_org_stats() -> any {
    return {
        "meals_saved": 2847,
        "people_helped": 1203,
        "donations_active": 12,
        "donations_expired": 3,
        "requests_fulfilled": 89,
        "avg_response_time": "2.4 hrs",
        "community_reach": "5.2 km",
        "events_hosted": 14,
        "volunteers": 23,
        "food_rescued_kg": 4200
    };
}

def:pub get_mock_ai_insights() -> list[any] {
    return [
        {
            "type": "demand_forecast",
            "title": "High demand expected in East Zone",
            "description": "Based on request patterns, East Village will see 40% more food requests this weekend.",
            "priority": "high",
            "action": "Pre-position donations in East Zone"
        },
        {
            "type": "expiry_alert",
            "title": "5 donations expiring in 24 hours",
            "description": "Dairy products and prepared meals need immediate redistribution.",
            "priority": "critical",
            "action": "Dispatch volunteers now"
        },
        {
            "type": "hotspot",
            "title": "Underserved area detected",
            "description": "Northside has 8 open requests but only 1 active donation within 3 km.",
            "priority": "high",
            "action": "Redirect donations to Northside"
        },
        {
            "type": "recommendation",
            "title": "Increase event capacity",
            "description": "Hot Meal Sunday is 78% full. Consider adding a second session.",
            "priority": "medium",
            "action": "Create additional event slot"
        }
    ];
}
