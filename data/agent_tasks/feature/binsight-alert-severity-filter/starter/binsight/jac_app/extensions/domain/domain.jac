"""Extended domain objects for BinSight waste analysis."""

obj PortionSize {
    has name: str;
    has ounces: float;
    has grams: float = 0.0;
    has servings_equivalent: float = 1.0;
}

obj CategoryProfile {
    has category: str;
    has default_unit_cost_usd: float = 0.0;
    has typical_portion_oz: float = 4.0;
    has is_perishable: bool = True;
    has shelf_life_hours: int = 4;
    has avoidability_bias: float = 0.6;
}

obj MenuWindow {
    has label: str;
    has starts_at: str;
    has ends_at: str;
    has meal_period: str;
    has station_count: int = 0;
}

obj WasteThreshold {
    has severity: str;
    has min_weight_oz: float;
    has max_weight_oz: float;
    has min_cost_usd: float;
    has escalate_to: str = "manager";
}

obj VisionPrompt {
    has instructions: str;
    has role: str = "system";
    has categories_allowed: list[str] = [];
    has response_format: str = "json";
    has temperature: float = 0.0;
}

obj MenuDelta {
    has action: str;
    has item_name: str;
    has reason: str = "";
    has estimated_savings_usd: float = 0.0;
}

obj AnalysisContext {
    has hall_id: str;
    has service_date: str;
    has meal_period: str;
    has current_menu: list[str] = [];
    has constant_items: list[str] = [];
    has prior_week_avoidable_oz: float = 0.0;
}

obj CostModel {
    has model_name: str = "usda_mid_tier";
    has category_rates: dict[str, float] = {};
    has currency: str = "USD";
    has last_synced: str = "";
}

obj ReportFormat {
    has kind: str = "summary";
    has include_line_items: bool = True;
    has include_trend: bool = False;
    has include_recommendations: bool = True;
    has locale: str = "en-US";
}

obj CaptureMetadata {
    has camera_model: str = "";
    has lens_mm: float = 0.0;
    has lighting: str = "overhead";
    has overhead_height_ft: float = 4.0;
    has resolution: str = "";
}

obj ScraperConfig {
    has user_agent: str = "BinSightBot/1.0";
    has timeout_seconds: int = 12;
    has retry_count: int = 2;
    has respect_robots: bool = True;
    has selector: str = "";
}

obj NormalizedMenuItem {
    has raw_name: str;
    has normalized_name: str;
    has category_guess: str = "other";
    has station_guess: str = "";
    has stripped_tokens: list[str] = [];
}

obj WasteDelta {
    has category: str;
    has prior_weight_oz: float = 0.0;
    has current_weight_oz: float = 0.0;
    has delta_oz: float = 0.0;
    has delta_pct: float = 0.0;
    has direction: str = "flat";
}

obj AuditTrailEntry {
    has timestamp: str;
    has action: str;
    has actor: str = "system";
    has target_id: str = "";
    has details: str = "";
}

obj ImagePreflightCheck {
    has passed: bool = True;
    has blur_score: float = 0.0;
    has brightness_score: float = 0.0;
    has coverage_pct: float = 100.0;
    has issues: list[str] = [];
}

obj SavingsProjection {
    has horizon_weeks: int = 4;
    has weekly_avoidable_oz: float = 0.0;
    has weekly_cost_usd: float = 0.0;
    has projected_savings_usd: float = 0.0;
    has assumptions: list[str] = [];
}

obj LLMUsageStat {
    has provider: str = "anthropic";
    has model: str = "";
    has input_tokens: int = 0;
    has output_tokens: int = 0;
    has latency_ms: int = 0;
    has cost_usd: float = 0.0;
}
