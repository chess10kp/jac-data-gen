# lib/manifest.jac — Deterministic manifest parsing and System 2 classification helpers.

def normalize_package_name(name: str) -> str;

def dedupe_incident_key(
    repo_full_name: str,
    commit_sha: str,
    manifest_path: str,
    dependency_name: str
) -> str;

def parse_manifest_deps(manifest_path: str, content: str) -> dict;

def manifest_delta(parent_deps: dict, current_deps: dict) -> dict;

def package_alias_map() -> dict;

def apply_package_alias(norm: str) -> str;

def parse_package_json_deps(content: str) -> dict;

def parse_requirements_txt_deps(content: str) -> dict;

def parse_toml_deps(content: str) -> dict;

def package_json_scripts_changed(parent_content: str, current_content: str) -> bool;

def pypi_publish_age_days(package_name: str) -> int;

def no_provenance_spec(version_spec: str) -> bool;

def importing_normalized_names_from_graph(import_edges_sources: list[str]) -> set;

def classify_dependency_risks(
    manifest_path: str,
    parent_content: str,
    current_content: str,
    added_deps: dict,
    graph_imports_normalized: set[str]
) -> list[dict];

def fix_invert_manifest(
    manifest_path: str,
    parent_content: str,
    current_content: str,
    dependency_name: str
) -> str;

def impl_likely_has_conventional_test(impl_path: str, test_file_paths: set[str]) -> bool;

def rank_gap_candidates(
    file_paths: list[str],
    paths_with_tests: set[str],
    paths_with_docs: set[str],
    core_prefixes: list[str]
) -> list[dict];

def requirements_line_pkg(line: str) -> str;
