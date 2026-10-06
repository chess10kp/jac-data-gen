# graph/builder.jac — Deterministic shared graph builder (System 1 + System 2).

import from graph.nodes { FileNode }

walker:pub GraphBuilderWalker {
    has repo_name: str = "";
    has repo_root: str = ".";
    has branch: str = "main";
    has force: bool = False;
    has file_count: int = 0;
    has edge_count: int = 0;
    has skip_paths: list[str] = ["__pycache__/", ".jac/", "node_modules/", "dist/", "build/"];
    has allowed_extensions: list[str] = [".jac", ".py", ".json", ".toml", ".txt", ".md"];

    can build with Root entry;

    def _should_skip(path: str) -> bool;
    def _detect_language(filename: str) -> str;
    def _read_local_file(abs_path: str) -> str;
    def _import_targets(path: str, language: str, content: str) -> list[str];
    def _jac_module_to_paths(source_path: str, module_path: str) -> list[str];
}
