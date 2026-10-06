enum StepKind {
    SYSTEM,
    USER,
    ASSISTANT,
    TOOL,
    COMMAND,
    EDIT,
    TEST,
    SUBMIT,
    ERROR,
    OTHER
}

enum RunStatus {
    SUBMITTED,
    RESOLVED,
    LIMITS_EXCEEDED,
    INTERRUPTED,
    ERROR_EXIT,
    UNKNOWN
}

enum FailureClass {
    PREMATURE_COMPLETION,
    INVALID_PATCH,
    WRONG_FILE_FOCUS,
    OSCILLATION_LOOP,
    TOOL_MISUSE,
    STALE_CONTEXT_OR_BAD_PLAN,
    REQUIREMENT_DRIFT,
    UNKNOWN
}

enum Severity {
    INFO,
    WARNING,
    ERROR,
    FATAL
}

node Corpus {
    has corpus_id: str;
    has name: str;
    has created_at: str;
}

node Batch {
    has batch_id: str;
    has name: str;
    has source_format: str;
    has created_at: str;
    has subset: str = "";
    has split: str = "";
    has run_count: int = 0;
}

node Run {
    has run_id: str;
    has batch_id: str;
    has instance_id: str = "";
    has task_title: str = "";
    has raw_path: str = "";
    has metadata: dict[str, any] = {};
    has exit_status: RunStatus = RunStatus.UNKNOWN;
    has api_calls: int = 0;
    has cost: float = 0.0;
    has step_count: int = 0;
    has unique_files: int = 0;
    has fingerprint: dict[str, any] = {};
    has primary_failure: FailureClass = FailureClass.UNKNOWN;
    has cluster_id: str = "";
    has critical_step_idx: int = -1;
    has summary: str = "";
}

node Step {
    has step_id: str;
    has idx: int;
    has kind: StepKind;
    has role: str;
    has phase: str = "other";
    has excerpt: str = "";
    has raw_offset: int = 0;
    has content_hash: str = "";
    has repeated: bool = False;
}

node FileArtifact {
    has path: str;
    has basename: str = "";
    has ext: str = "";
}

node Patch {
    has patch_id: str;
    has file_path: str = "";
    has adds: int = 0;
    has dels: int = 0;
    has parse_ok: bool = True;
    has patch_hash: str = "";
}

node TestEvent {
    has test_id: str;
    has command: str = "";
    has status: str = "";
    has failing_tests: list[str] = [];
    has excerpt: str = "";
}

node ErrorEvent {
    has error_id: str;
    has error_type: str = "";
    has message: str = "";
    has severity: Severity = Severity.ERROR;
}

node FailureHypothesis {
    has hyp_id: str;
    has label: FailureClass;
    has score: float = 0.0;
    has rationale: str = "";
}

node Cluster {
    has cluster_id: str;
    has label: str = "";
    has failure_class: FailureClass = FailureClass.UNKNOWN;
    has size: int = 0;
    has medoid_run_id: str = "";
    has summary: str = "";
}

node MemoryPatch {
    has patch_id: str;
    has scope: str = "";
    has title: str = "";
    has diff_text: str = "";
    has confidence: float = 0.0;
}

obj EvidenceRef {
    has step_idx: int;
    has artifact: str;
    has quote: str = "";
}

obj RunDiagnosis {
    has failure_class: FailureClass = FailureClass.UNKNOWN;
    has critical_step_idx: int = -1;
    has irreversible_because: str = "";
    has evidence: list[EvidenceRef] = [];
    has confidence: float = 0.0;
}

obj ClusterLabel {
    has label: str;
    has summary: str = "";
    has confidence: float = 0.0;
}

obj MemoryRule {
    has title: str;
    has rationale: str = "";
    has rule_text: str = "";
    has supported_by_steps: list[int] = [];
    has confidence: float = 0.0;
}

obj MemoryPatchProposal {
    has scope: str;
    has cluster_label: str = "";
    has summary: str = "";
    has rules: list[MemoryRule] = [];
    has diff_text: str = "";
}

obj ComparisonVerdict {
    has winner: str = "";
    has raw_score: float = 0.0;
    has structured_score: float = 0.0;
    has evidence_validity_winner: str = "";
    has pivot_quality_winner: str = "";
    has specificity_winner: str = "";
    has actionability_winner: str = "";
    has hallucination_winner: str = "";
    has rationale: str = "";
}

edge HasBatch {}
edge HasRun { has order: int = 0; }
edge HasStep { has order: int = 0; }
edge NextStep {}
edge TouchesFile {}
edge ProducesPatch {}
edge PatchesFile {}
edge RunsTest {}
edge RaisesError {}
edge SupportsHypothesis { has weight: float = 0.0; }
edge InCluster {}
edge SimilarRun { has score: float = 0.0; }
edge EvidencedBy {}
edge SuggestsPatch { has weight: float = 0.0; }
edge ContrastRun { has score: float = 0.0; }
