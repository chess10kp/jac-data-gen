"""Graph model definitions: nodes, edges, and enums."""


# ── Enums ────────────────────────────────────────────────────

enum EventType {
    MAINTENANCE,
    PAYMENT,
    LEASE,
    COMPLAINT,
    INQUIRY
}

sem EventType.MAINTENANCE = "Any physical repair or service need in the unit or building: broken items, leaks, no heat or AC, water damage, mold, power outage, electrical issues, plumbing, appliance failure, structural damage, pest control";
sem EventType.PAYMENT = "Rent payments, billing, late fees, payment plans";
sem EventType.LEASE = "Lease terms, renewal, move-in, move-out, lease questions";
sem EventType.COMPLAINT = "Noise complaints, neighbor disputes, common area issues (not physical repairs)";
sem EventType.INQUIRY = "General questions, information requests, amenity questions";

enum UrgencyLevel {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}

sem UrgencyLevel.LOW = "Non-urgent, can be scheduled within a week";
sem UrgencyLevel.MEDIUM = "Should be addressed within 1-2 days";
sem UrgencyLevel.HIGH = "Needs same-day attention, potential property damage";
sem UrgencyLevel.CRITICAL = "Emergency: safety hazard, fire risk, flooding, gas leak";


# ── Nodes ────────────────────────────────────────────────────

node Property {
    has name: str = "";
    has address: str = "";
    has city: str = "";
    has state: str = "";
    has zip_code: str = "";
}

node Unit {
    has number: str = "";
    has bedrooms: int = 1;
    has bathrooms: int = 1;
    has sq_ft: int = 0;
    has status: str = "occupied";
}

node Lease {
    has start_date: str = "";
    has end_date: str = "";
    has rent_amount: float = 0.0;
    has deposit: float = 0.0;
    has status: str = "active";
}

node Tenant {
    has name: str = "";
    has phone: str = "";
    has email: str = "";
    has payment_status: str = "current";
    has move_in_date: str = "";
}

node Ticket {
    has ticket_id: str = "";
    has category: str = "";
    has description: str = "";
    has urgency: str = "medium";
    has status: str = "open";
    has ai_summary: str = "";
    has ai_diagnosis: str = "";
    has recommended_action: str = "";
    has tenant_reply: str = "";
    has owner_alert: str = "";
    has created_at: str = "";
    has resolved_at: str = "";
    has vendor_name: str = "";
    has estimated_cost: float = 0.0;
}

node Vendor {
    has name: str = "";
    has category: str = "";
    has phone: str = "";
    has email: str = "";
    has rating: float = 0.0;
    has avg_cost: float = 0.0;
    has available: bool = True;
}


# ── Edges ────────────────────────────────────────────────────

edge HasUnit {}
edge HasLease {}
edge HasTenant {}
edge HasTicket {}

edge Services {
    has jobs_completed: int = 0;
    has total_spent: float = 0.0;
    has last_service_date: str = "";
}

edge AssignedTo {}
