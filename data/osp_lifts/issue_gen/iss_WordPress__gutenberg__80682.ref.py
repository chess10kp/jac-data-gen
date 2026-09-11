"""Reference harness for iss_WordPress__gutenberg__80682."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_WordPress__gutenberg__80682.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
ADVISORIES = [
    {
        "id": "GHSA-xcpc-8h2w-3j85",
        "aliases": ["GHSA-xcpc-8h2w-3j85"],
        "package": "adm-zip",
        "kind": "vulnerability",
    },
    {
        "id": "GHSA-5c6j-r48x-rmvq",
        "aliases": ["GHSA-5c6j-r48x-rmvq", "GHSA-qj8w-gfj5-8c6v"],
        "package": "serialize-javascript",
        "kind": "vulnerability",
    },
    {
        "id": "GHSA-qj8w-gfj5-8c6v",
        "aliases": ["GHSA-5c6j-r48x-rmvq", "GHSA-qj8w-gfj5-8c6v"],
        "package": "serialize-javascript",
        "kind": "vulnerability",
    },
    {
        "id": "GHSA-linkify",
        "aliases": ["GHSA-linkify"],
        "package": "linkify-it",
        "kind": "vulnerability",
    },
    {
        "id": "GHSA-minimatch",
        "aliases": ["GHSA-minimatch"],
        "package": "minimatch",
        "kind": "vulnerability",
    },
    {
        "id": "GHSA-w5hq-g745-h8pq",
        "aliases": ["GHSA-w5hq-g745-h8pq"],
        "package": "uuid",
        "kind": "vulnerability",
    },
    {
        "id": "GHSA-8988-4f7v-96qf",
        "aliases": ["GHSA-8988-4f7v-96qf"],
        "package": "@opentelemetry/core",
        "kind": "vulnerability",
    },
    {
        "id": "INFO-webpack",
        "aliases": ["INFO-webpack"],
        "package": "webpack-dev-server",
        "kind": "maintenance",
    },
]

G = _mod.load_package_graph(
    [
        ("@wordpress/scripts", "33.0.0"),
        ("adm-zip", "0.5.18"),
        ("copy-webpack-plugin", "10.2.4"),
        ("serialize-javascript", "6.0.2"),
        ("markdownlint-cli", "0.31.1"),
        ("markdownlint", "0.25.1"),
        ("markdown-it", "12.3.2"),
        ("linkify-it", "3.0.3"),
        ("minimatch", "3.0.8"),
        ("webpack-dev-server", "4.15.2"),
        ("sockjs", "0.3.24"),
        ("uuid", "8.3.2"),
        ("@wordpress/e2e-test-utils-playwright", "1.51.0"),
        ("lighthouse", "12.8.2"),
        ("@sentry/node", "9.47.1"),
        ("@opentelemetry/core", "1.30.1"),
    ],
    [
        ("@wordpress/scripts", "adm-zip"),
        ("@wordpress/scripts", "copy-webpack-plugin"),
        ("copy-webpack-plugin", "serialize-javascript"),
        ("@wordpress/scripts", "markdownlint-cli"),
        ("markdownlint-cli", "markdownlint"),
        ("markdownlint-cli", "minimatch"),
        ("markdownlint", "markdown-it"),
        ("markdown-it", "linkify-it"),
        ("@wordpress/scripts", "webpack-dev-server"),
        ("webpack-dev-server", "sockjs"),
        ("sockjs", "uuid"),
        ("@wordpress/scripts", "@wordpress/e2e-test-utils-playwright"),
        ("@wordpress/e2e-test-utils-playwright", "lighthouse"),
        ("lighthouse", "@sentry/node"),
        ("@sentry/node", "@opentelemetry/core"),
    ],
    root_declared={
        "adm-zip": "^0.5.18",
        "copy-webpack-plugin": "^10.2.4",
        "markdownlint-cli": "^0.31.1",
        "webpack-dev-server": "^4.15.1",
        "@wordpress/e2e-test-utils-playwright": "^1.51.0",
    },
)

assert _mod.direct_dependencies(G, "@wordpress/scripts") == [
    "@wordpress/e2e-test-utils-playwright",
    "adm-zip",
    "copy-webpack-plugin",
    "markdownlint-cli",
    "webpack-dev-server",
]
assert _mod.direct_dependencies(G, "missing-pkg") == []

assert _mod.transitive_dependencies(G, "@wordpress/scripts") == [
    "@opentelemetry/core",
    "@sentry/node",
    "@wordpress/e2e-test-utils-playwright",
    "adm-zip",
    "copy-webpack-plugin",
    "lighthouse",
    "linkify-it",
    "markdown-it",
    "markdownlint",
    "markdownlint-cli",
    "minimatch",
    "serialize-javascript",
    "sockjs",
    "uuid",
    "webpack-dev-server",
]
assert _mod.transitive_dependencies(G, "adm-zip") == []
assert _mod.transitive_dependencies(G, "ghost") == []

assert _mod.dependency_paths(G, "@wordpress/scripts", "serialize-javascript") == [
    ["@wordpress/scripts", "copy-webpack-plugin", "serialize-javascript"],
]
assert _mod.dependency_paths(G, "@wordpress/scripts", "uuid") == [
    ["@wordpress/scripts", "webpack-dev-server", "sockjs", "uuid"],
]
assert _mod.dependency_paths(G, "@wordpress/scripts", "linkify-it") == [
    [
        "@wordpress/scripts",
        "markdownlint-cli",
        "markdownlint",
        "markdown-it",
        "linkify-it",
    ],
]
assert _mod.dependency_paths(
    G, "@wordpress/scripts", "@opentelemetry/core"
) == [
    [
        "@wordpress/scripts",
        "@wordpress/e2e-test-utils-playwright",
        "lighthouse",
        "@sentry/node",
        "@opentelemetry/core",
    ],
]
assert _mod.dependency_paths(
    G, "@wordpress/scripts", "@opentelemetry/core", max_depth=3
) == []
assert _mod.dependency_paths(G, "missing", "uuid") == []
assert _mod.dependency_paths(G, "@wordpress/scripts", "ghost") == []

deduped = _mod.dedupe_advisory_aliases(ADVISORIES)
assert [r["id"] for r in deduped] == [
    "GHSA-5c6j-r48x-rmvq",
    "GHSA-8988-4f7v-96qf",
    "GHSA-linkify",
    "GHSA-minimatch",
    "GHSA-w5hq-g745-h8pq",
    "GHSA-xcpc-8h2w-3j85",
    "INFO-webpack",
]

assert _mod.reachable_vulnerability_ids(G, "@wordpress/scripts", ADVISORIES) == [
    "GHSA-5c6j-r48x-rmvq",
    "GHSA-8988-4f7v-96qf",
    "GHSA-linkify",
    "GHSA-minimatch",
    "GHSA-w5hq-g745-h8pq",
    "GHSA-xcpc-8h2w-3j85",
]
assert _mod.reachable_vulnerability_ids(G, "adm-zip", ADVISORIES) == [
    "GHSA-xcpc-8h2w-3j85",
]
assert _mod.reachable_vulnerability_ids(G, "@wordpress/scripts", []) == []

assert _mod.changelog_declared_drift(
    G, "@wordpress/scripts", {"webpack-dev-server": "^5.2.1"}
) == ["webpack-dev-server"]
assert _mod.changelog_declared_drift(
    G, "@wordpress/scripts", {"adm-zip": "^0.5.18"}
) == []
assert _mod.changelog_declared_drift(G, "missing", {"webpack-dev-server": "^5.2.1"}) == []

CYC = _mod.load_package_graph(
    [
        ("a", "1.0.0"),
        ("b", "1.0.0"),
        ("c", "1.0.0"),
        ("leaf", "1.0.0"),
    ],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
)
assert _mod.transitive_dependencies(CYC, "a") == ["b", "c", "leaf"]
assert _mod.dependency_paths(CYC, "a", "a") == [["a"]]
assert _mod.dependency_paths(CYC, "a", "c", max_depth=2) == []
assert _mod.dependency_paths(CYC, "a", "c", max_depth=3) == [["a", "b", "c"]]

DIAM = _mod.load_package_graph(
    [
        ("root", "1.0.0"),
        ("left", "1.0.0"),
        ("right", "1.0.0"),
        ("sink", "1.0.0"),
    ],
    [
        ("root", "right"),
        ("root", "left"),
        ("right", "sink"),
        ("left", "sink"),
    ],
)
assert _mod.dependency_paths(DIAM, "root", "sink") == [
    ["root", "left", "sink"],
    ["root", "right", "sink"],
]
assert _mod.reachable_vulnerability_ids(DIAM, "root", ADVISORIES) == []
print("iss_WordPress__gutenberg__80682 ref OK")
