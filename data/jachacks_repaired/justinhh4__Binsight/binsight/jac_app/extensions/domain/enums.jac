"""Enumerations for BinSight domain constraints."""

enum MealPeriod {
    BREAKFAST = "breakfast",
    BRUNCH = "brunch",
    LUNCH = "lunch",
    DINNER = "dinner",
    LATE_NIGHT = "late_night"
}

enum WasteCategory {
    PROTEIN = "protein",
    GRAIN = "grain",
    DAIRY = "dairy",
    FRUIT = "fruit",
    VEGETABLE = "vegetable",
    BEVERAGE = "beverage",
    OTHER = "other"
}

enum WasteSeverity {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    CRITICAL = "critical"
}

enum RecommendationPriority {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high"
}

enum RecommendationStatus {
    OPEN = "open",
    IN_PROGRESS = "in_progress",
    APPLIED = "applied",
    DISMISSED = "dismissed"
}

enum ServiceStyle {
    SELF_SERVE = "self-serve",
    STAFFED = "staffed",
    GRAB_AND_GO = "grab_and_go",
    BUFFET = "buffet"
}

enum MenuSource {
    URL = "url",
    MANUAL = "manual",
    NONE = "none"
}

enum TrendDirection {
    UP = "up",
    DOWN = "down",
    FLAT = "flat"
}

enum ReviewerRole {
    MANAGER = "manager",
    CHEF = "chef",
    SUSTAINABILITY_LEAD = "sustainability_lead",
    AUDITOR = "auditor"
}

enum AlertChannel {
    EMAIL = "email",
    SMS = "sms",
    DASHBOARD = "dashboard",
    SLACK = "slack"
}

enum ScrapeStatus {
    PENDING = "pending",
    RUNNING = "running",
    SUCCEEDED = "succeeded",
    FAILED = "failed",
    SKIPPED = "skipped"
}

enum AvoidabilityReason {
    OVERPRODUCED = "overproduced",
    EXPIRED = "expired",
    PLATE_WASTE = "plate_waste",
    PREP_TRIM = "prep_trim",
    SPOILAGE = "spoilage",
    GUEST_PREFERENCE = "guest_preference"
}
