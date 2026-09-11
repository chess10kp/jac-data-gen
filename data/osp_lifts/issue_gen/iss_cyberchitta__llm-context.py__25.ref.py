"""Reference harness for iss_cyberchitta__llm-context.py__25."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_cyberchitta__llm-context.py__25.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
G = load_context_graph(
    [
        ("frontend/Scene.tsx", "ui", 12.0),
        ("frontend/Renderer.ts", "render", 45.0),
        ("frontend/Shader.ts", "render", 30.0),
        ("frontend/WebGLManager.ts", "render", 20.0),
        ("backend/auth.py", "api", 8.0),
        ("backend/session_middleware.py", "api", 6.0),
        ("backend/oauth_flow.py", "api", 10.0),
        ("tests/test_renderer.py", "test", 4.0),
        ("tests/test_auth.py", "test", 3.0),
    ],
    [
        ("frontend/Scene.tsx", "frontend/Renderer.ts"),
        ("frontend/Renderer.ts", "frontend/Shader.ts"),
        ("frontend/Shader.ts", "frontend/WebGLManager.ts"),
        ("frontend/Renderer.ts", "frontend/WebGLManager.ts"),
        ("backend/oauth_flow.py", "backend/auth.py"),
        ("backend/auth.py", "backend/session_middleware.py"),
        ("tests/test_renderer.py", "frontend/Renderer.ts"),
        ("tests/test_auth.py", "backend/oauth_flow.py"),
    ],
)

assert transitive_imports(G, "frontend/Scene.tsx") == [
    "frontend/Renderer.ts",
    "frontend/Shader.ts",
    "frontend/WebGLManager.ts",
]
assert transitive_imports(G, "backend/oauth_flow.py") == [
    "backend/auth.py",
    "backend/session_middleware.py",
]
assert transitive_imports(G, "frontend/WebGLManager.ts") == []
assert transitive_imports(G, "missing") == []

assert import_paths(G, "frontend/Scene.tsx", "frontend/WebGLManager.ts") == [
    [
        "frontend/Scene.tsx",
        "frontend/Renderer.ts",
        "frontend/Shader.ts",
        "frontend/WebGLManager.ts",
    ],
    [
        "frontend/Scene.tsx",
        "frontend/Renderer.ts",
        "frontend/WebGLManager.ts",
    ],
]
assert import_paths(G, "frontend/Scene.tsx", "frontend/WebGLManager.ts", max_depth=3) == [
    ["frontend/Scene.tsx", "frontend/Renderer.ts", "frontend/WebGLManager.ts"],
]
assert import_paths(G, "missing", "frontend/Renderer.ts") == []
assert import_paths(G, "frontend/Scene.tsx", "ghost") == []

assert impact_by_kind(G, "frontend/Scene.tsx") == {
    "render": [
        "frontend/Renderer.ts",
        "frontend/Shader.ts",
        "frontend/WebGLManager.ts",
    ],
}
assert impact_by_kind(G, "backend/oauth_flow.py") == {
    "api": ["backend/auth.py", "backend/session_middleware.py"],
}
assert impact_by_kind(G, "tests/test_renderer.py") == {
    "render": [
        "frontend/Renderer.ts",
        "frontend/Shader.ts",
        "frontend/WebGLManager.ts",
    ],
}
assert impact_by_kind(G, "missing") == {}

assert preview_token_kb(G, "frontend/Scene.tsx") == 107.0
assert preview_token_kb(G, "backend/oauth_flow.py") == 24.0
assert preview_token_kb(G, "missing") == 0.0

assert rule_context_files(G, ["frontend/Scene.tsx"], expand_deps=True) == [
    "frontend/Renderer.ts",
    "frontend/Scene.tsx",
    "frontend/Shader.ts",
    "frontend/WebGLManager.ts",
]
assert rule_context_files(G, ["frontend/Scene.tsx"], expand_deps=False) == [
    "frontend/Scene.tsx",
]
assert rule_context_files(G, ["ghost"], expand_deps=True) == []
assert rule_context_files(
    G, ["frontend/Scene.tsx", "backend/oauth_flow.py"], expand_deps=True
) == [
    "backend/auth.py",
    "backend/oauth_flow.py",
    "backend/session_middleware.py",
    "frontend/Renderer.ts",
    "frontend/Scene.tsx",
    "frontend/Shader.ts",
    "frontend/WebGLManager.ts",
]

CYC = load_context_graph(
    [
        ("a", "render", 1.0),
        ("b", "render", 1.0),
        ("c", "dev", 1.0),
        ("leaf", "render", 1.0),
    ],
    [
        ("a", "b"),
        ("b", "c"),
        ("c", "a"),
        ("c", "leaf"),
    ],
)
assert transitive_imports(CYC, "a") == ["b", "c", "leaf"]
assert import_paths(CYC, "a", "a") == [["a"]]
assert import_paths(CYC, "a", "c", max_depth=2) == []
assert import_paths(CYC, "a", "c", max_depth=3) == [["a", "b", "c"]]

DIAM = load_context_graph(
    [
        ("root", "ui", 1.0),
        ("left", "render", 1.0),
        ("right", "render", 1.0),
        ("sink", "test", 1.0),
    ],
    [
        ("root", "right"),
        ("root", "left"),
        ("right", "sink"),
        ("left", "sink"),
    ],
)
assert import_paths(DIAM, "root", "sink") == [
    ["root", "left", "sink"],
    ["root", "right", "sink"],
]
print("iss_cyberchitta__llm-context.py__25 ref OK")
