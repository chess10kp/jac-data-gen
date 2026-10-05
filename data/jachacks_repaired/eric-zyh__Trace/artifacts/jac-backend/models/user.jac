"""User and authentication data models for Trace."""

enum TrustLevel {
    FULL_TRUST,
    TRUSTED,
    USE_ONLY,
    EPHEMERAL
}

obj DeviceRecord {
    has device_id: str = "";
    has device_name: str = "";
    has trust_level: TrustLevel = TrustLevel.EPHEMERAL;
    has last_active: str = "";
    has registered: str = "";
}

node UserProfile {
    has user_id: str = "";
    has display_name: str = "";
    has email: str = "";
    has created_at: str = "";
    has devices: list[DeviceRecord] = [];
    has onboarding_complete: bool = False;
    has personalization_score: float = 0.0;
}

node CorrectionRecord {
    has correction_type: str = "";
    has original: str = "";
    has corrected: str = "";
    has context: str = "";
    has timestamp: str = "";
}

edge CorrectionEdge {
    has correction_type: str = "";
}
