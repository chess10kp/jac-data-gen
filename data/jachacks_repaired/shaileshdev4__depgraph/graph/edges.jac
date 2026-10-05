"""DepGraph OSP edge definitions."""

edge DependsOn {
    has is_transitive: bool = True;
    has required_version: str = "";
}

edge HasCVE;

edge HasContext;

edge Resolves;

edge BlockedBy;
