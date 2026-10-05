"""Preference and reward engine data models for Trace."""

node PreferenceComparison {
    has prompt: str = "";
    has generation_a: str = "";
    has generation_b: str = "";
    has user_choice: str = "";
    has user_edit: str = "";
    has style_rating: float = 0.0;
    has utility_rating: float = 0.0;
    has timestamp: str = "";
    has context: str = "";
}

obj RewardWeights {
    has style_weight: float = 0.25;
    has utility_weight: float = 0.25;
    has timing_weight: float = 0.25;
    has decision_weight: float = 0.25;
}

node RewardModel {
    has weights: RewardWeights = RewardWeights();
    has total_comparisons: int = 0;
    has last_updated: str = "";
}
