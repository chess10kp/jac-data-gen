"""Graph node archetypes for the BinSight dining hall waste domain."""

node DiningHall {
    has hall_id: str;
    has name: str;
    has campus: str = "University of Michigan";
    has seating_capacity: int = 0;
    has avg_daily_covers: int = 0;
    has manager_email: str = "";
    has opens_at: str = "07:00";
    has closes_at: str = "21:00";
    has active: bool = True;
}

node MealService {
    has service_id: str;
    has hall_id: str;
    has meal_period: str;
    has service_date: str;
    has covers_served: int = 0;
    has station_count: int = 0;
    has notes: str = "";
}

node Station {
    has station_id: str;
    has name: str;
    has service_style: str = "self-serve";
    has staffed: bool = True;
    has rotation_label: str = "";
}

node MenuItem {
    has item_id: str;
    has name: str;
    has category: str = "other";
    has station_label: str = "";
    has unit_cost_usd: float = 0.0;
    has per_serving_oz: float = 0.0;
    has is_vegetarian: bool = False;
    has is_vegan: bool = False;
    has contains_dairy: bool = False;
    has contains_gluten: bool = False;
    has is_constant: bool = False;
}

node WasteBin {
    has bin_id: str;
    has hall_id: str;
    has station_label: str = "";
    has capacity_gallons: float = 23.0;
    has liner_type: str = "compostable";
    has photographed_at: str = "";
    has image_path: str = "";
    has image_media_type: str = "image/jpeg";
}

node WasteRecord {
    has record_id: str;
    has bin_id: str;
    has captured_at: str;
    has total_weight_oz: float = 0.0;
    has total_cost_usd: float = 0.0;
    has avoidable_weight_oz: float = 0.0;
    has unavoidable_weight_oz: float = 0.0;
    has severity: str = "low";
    has reviewer: str = "";
    has approved: bool = False;
}

node WasteLineItem {
    has line_id: str;
    has food: str;
    has category: str = "other";
    has estimated_weight_oz: float = 0.0;
    has estimated_portion_wasted_pct: float = 0.0;
    has estimated_cost_usd: float = 0.0;
    has avoidable: bool = True;
    has matched_menu_item_id: str = "";
    has confidence: float = 0.0;
}

node Recommendation {
    has rec_id: str;
    has generated_at: str;
    has action: str;
    has priority: str = "medium";
    has rationale: str = "";
    has target_meal_period: str = "";
    has expected_savings_usd: float = 0.0;
    has status: str = "open";
    has owner: str = "";
}

node MenuCycle {
    has cycle_id: str;
    has label: str;
    has week_of: str;
    has hall_id: str;
    has rotation_length_days: int = 14;
    has active: bool = True;
}

node ScrapeJob {
    has job_id: str;
    has source_url: str;
    has started_at: str;
    has finished_at: str = "";
    has items_found: int = 0;
    has success: bool = False;
    has error_message: str = "";
}

node CostBaseline {
    has baseline_id: str;
    has category: str;
    has dollars_per_oz: float = 0.0;
    has sourced_from: str = "USDA";
    has last_updated: str = "";
}

node Reviewer {
    has reviewer_id: str;
    has name: str;
    has role: str = "manager";
    has email: str = "";
    has halls_managed: list[str] = [];
}

node Alert {
    has alert_id: str;
    has created_at: str;
    has subject: str;
    has severity: str = "medium";
    has body: str = "";
    has acknowledged: bool = False;
    has hall_id: str = "";
}

node AlertNote {
    has note_id: str;
    has author: str;
    has text: str;
    has created_at: str;
}

node TrendPoint {
    has point_id: str;
    has hall_id: str;
    has week_of: str;
    has avoidable_weight_oz: float = 0.0;
    has unavoidable_weight_oz: float = 0.0;
    has total_cost_usd: float = 0.0;
    has covers_served: int = 0;
}
