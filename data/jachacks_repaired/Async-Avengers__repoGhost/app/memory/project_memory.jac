import from app.models.core { DecisionItem, BlockerItem, FileMatch }

obj ProjectMemory {
    has project_key: str = "";
    has conventions: list[str] = [];
    has decisions: list[DecisionItem] = [];
    has repeated_blockers: list[BlockerItem] = [];
    has prior_summaries: list[str] = [];
    has language_to_code_mappings: list[FileMatch] = [];
}
