"""Persona engine data models for Trace."""

enum ContextType {
    WORK,
    FAMILY,
    FRIENDS,
    FORMAL,
    CASUAL,
    LATE_NIGHT,
    STRESS,
    CREATIVE
}

obj ToneParams {
    has directness: float = 0.5;
    has warmth: float = 0.5;
    has formality: float = 0.5;
    has humor: float = 0.3;
    has verbosity: float = 0.5;
}

node PersonaState {
    has context: ContextType = ContextType.CASUAL;
    has tone_params: ToneParams = ToneParams();
    has vocabulary_profile: list[str] = [];
    has boundary_rules: list[str] = [];
    has activation_conditions: list[str] = [];
    has confidence: float = 0.5;
    has training_examples: int = 0;
}

node PersonaCore {
    has base_style_description: str = "";
    has emotional_range: str = "";
    has communication_values: list[str] = [];
    has active_context: ContextType = ContextType.CASUAL;
}

edge PersonaTransition {
    has trigger: str = "";
    has transition_style: str = "";
    has probability: float = 0.5;
}
