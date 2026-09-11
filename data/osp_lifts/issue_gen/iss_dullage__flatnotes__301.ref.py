"""Reference harness for dullage/flatnotes#301."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "fn301", HERE / "iss_dullage__flatnotes__301.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules["fn301"] = mod
spec.loader.exec_module(mod)

load_vfs = mod.load_vfs
index_markdown = mod.index_markdown


def _main_entries() -> list[tuple[str, str, str | None]]:
    return [
        ("/notes", "folder", None),
        ("/notes/readme.md", "file", "/notes"),
        ("/notes/guide", "folder", "/notes"),
        ("/notes/guide/intro.md", "file", "/notes/guide"),
        ("/notes/guide/advanced.md", "file", "/notes/guide"),
        ("/notes/assets", "folder", "/notes"),
        ("/notes/assets/logo.png", "file", "/notes/assets"),
        ("/notes/draft.txt", "file", "/notes"),
    ]


def main() -> None:
    g = load_vfs(_main_entries())
    assert index_markdown(g, "/notes") == [
        "/notes/guide/advanced.md",
        "/notes/guide/intro.md",
        "/notes/readme.md",
    ]
    assert index_markdown(g, "/notes/guide") == [
        "/notes/guide/advanced.md",
        "/notes/guide/intro.md",
    ]
    assert index_markdown(g, "/notes/guide/intro.md") == []
    assert index_markdown(g, "/missing") == []

    cyc = load_vfs([
        ("/a", "folder", None),
        ("/b", "folder", "/a"),
        ("/c", "folder", "/b"),
        ("/notes/hidden.md", "file", "/c"),
        ("/a", "folder", "/c"),
    ])
    assert index_markdown(cyc, "/a") == ["/notes/hidden.md"]

    wide = load_vfs([
        ("/vault", "folder", None),
        ("/vault/w1", "folder", "/vault"),
        ("/vault/w1/a.md", "file", "/vault/w1"),
        ("/vault/w2", "folder", "/vault"),
        ("/vault/w2/b.md", "file", "/vault/w2"),
        ("/vault/w3", "folder", "/vault"),
        ("/vault/w3/c.md", "file", "/vault/w3"),
        ("/vault/w1/deep", "folder", "/vault/w1"),
        ("/vault/w1/deep/nested.md", "file", "/vault/w1/deep"),
    ])
    assert index_markdown(wide, "/vault") == [
        "/vault/w1/a.md",
        "/vault/w1/deep/nested.md",
        "/vault/w2/b.md",
        "/vault/w3/c.md",
    ]
    print("ok")


if __name__ == "__main__":
    main()
