obj RepoSelection {
    has repo_path: str = "";
    has repo_name: str = "";
    has branch: str = "main";
    has is_valid: bool = False;
}

obj ChatMessage {
    has role: str = "user";
    has content: str = "";
    has created_at: str = "";
}

obj DecisionItem {
    has title: str = "";
    has detail: str = "";
    has confidence: float = 0.0;
    has source: str = "";
}

obj BlockerItem {
    has title: str = "";
    has detail: str = "";
    has severity: str = "medium";
    has owner_hint: str = "";
}

obj FileMatch {
    has path: str = "";
    has score: float = 0.0;
    has rationale: str = "";
    has kind: str = "file";
}

obj OwnershipGuess {
    has area: str = "";
    has owner: str = "";
    has confidence: float = 0.0;
    has rationale: str = "";
}

obj MeetingSummary {
    has summary: str = "";
    has action_items: list[str] = [];
    has decisions: list[DecisionItem] = [];
    has blockers: list[BlockerItem] = [];
    has people: list[str] = [];
    has systems: list[str] = [];
    has deadlines: list[str] = [];
    has uncertainty: list[str] = [];
}
