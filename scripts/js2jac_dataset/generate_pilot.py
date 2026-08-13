#!/usr/bin/env python3
"""Generate the deterministic 100-component js2jac pilot corpus (Pilot A).

Sources land in jaseci/jac/tests/compiler/js2jac/pilot/ as numbered files.
Re-running with the same PILOT_SEED yields byte-identical output.

Usage:
    ./generate_pilot.py [--out DIR] [--manifest PATH]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import textwrap

PILOT_SEED = 20260810
RULE_SET_VERSION = "js2jac-client-v1"
GENERATOR_VERSION = "pilot-v1"
LICENSE = "CC0-1.0"

DEFAULT_OUT = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "..", "jaseci", "jac", "tests", "compiler", "js2jac", "pilot")
)


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _record_id(source: str) -> str:
    return _sha256(source)


def _wrap(body: str, width: int = 88) -> str:
    return textwrap.dedent(body).strip() + "\n"


# ---------------------------------------------------------------------------
# Template families — each returns (relative_path, source, family, rule_tags)
# ---------------------------------------------------------------------------

def family_basic_props(i: int) -> tuple[str, str, str, list[str]]:
    kinds = ["string", "number", "boolean"]
    kind = kinds[i % 3]
    if kind == "string":
        src = _wrap(
            f"""
            export function app(props: {{ label: string }}) {{
              return <div>{{props.label}}</div>;
            }}
            """
        )
        tags = ["props-bag", "jsx-intrinsic", "ts-inline-props"]
    elif kind == "number":
        src = _wrap(
            f"""
            export function app(props: {{ count: number }}) {{
              return <span>{{props.count}}</span>;
            }}
            """
        )
        tags = ["props-bag", "numeric-prop"]
    else:
        src = _wrap(
            f"""
            export function app(props: {{ active: boolean }}) {{
              return <p>{{props.active ? "on" : "off"}}</p>;
            }}
            """
        )
        tags = ["props-bag", "jsx-conditional"]
    return f"pilot_{i:03d}_basic_props_{kind}.tsx", src, "basic_props", tags


def family_destructure(i: int) -> tuple[str, str, str, list[str]]:
    variants = [
        (
            "tsx",
            _wrap(
                """
                export function app({ id, label }: { id: string; label?: string }) {
                  return <div>{id}{label}</div>;
                }
                """
            ),
            ["destructure-props", "optional-prop"],
        ),
        (
            "tsx",
            _wrap(
                """
                export function app({ title, count }: { title: string; count: number }) {
                  return <h1>{title} ({count})</h1>;
                }
                """
            ),
            ["destructure-props"],
        ),
        (
            "tsx",
            _wrap(
                """
                type RowProps = { key: string; value: string };
                export function app({ key, value }: RowProps) {
                  return <div>{key}:{value}</div>;
                }
                """
            ),
            ["destructure-props", "external-props-alias"],
        ),
    ]
    ext, src, tags = variants[i % len(variants)]
    return f"pilot_{i:03d}_destructure.{ext}", src, "destructure", tags


def family_jsx_attrs(i: int) -> tuple[str, str, str, list[str]]:
    src = _wrap(
        f"""
        export function app(props: {{ name: string; level: number }}) {{
          return (
            <div className="card" id={{"item-" + props.name}} data-level={{props.level}}>
              <span title={{props.name}}>{{props.name}}</span>
            </div>
          );
        }}
        """
    )
    return f"pilot_{i:03d}_jsx_attrs.tsx", src, "jsx_attrs", ["jsx-attributes", "template-literal"]


def family_jsx_conditionals(i: int) -> tuple[str, str, str, list[str]]:
    patterns = [
        (
            _wrap(
                """
                export function app(props: { show: boolean }) {
                  return <div>{props.show ? <span>yes</span> : <span>no</span>}</div>;
                }
                """
            ),
            ["jsx-ternary"],
        ),
        (
            _wrap(
                """
                export function app(props: { show: boolean; items: string[] }) {
                  return <div>{props.show && <ul>{props.items.map(x => <li key={x}>{x}</li>)}</ul>}</div>;
                }
                """
            ),
            ["jsx-and", "jsx-list"],
        ),
        (
            _wrap(
                """
                export function app(props: { message: string }) {
                  return <div>{props.message || <em>empty</em>}</div>;
                }
                """
            ),
            ["jsx-or"],
        ),
    ]
    src, tags = patterns[i % len(patterns)]
    return f"pilot_{i:03d}_jsx_cond.tsx", src, "jsx_conditionals", tags


def family_jsx_lists(i: int) -> tuple[str, str, str, list[str]]:
    params = ["item", "row", "entry"]
    param = params[i % 3]
    src = _wrap(
        f"""
        export function app(props: {{ items: string[] }}) {{
          return (
            <ul>
              {{props.items.map({param} => <li key={{{param}}}>{param}</li>)}}
            </ul>
          );
        }}
        """
    )
    return f"pilot_{i:03d}_jsx_list.tsx", src, "jsx_lists", ["jsx-list", "comprehension"]


def family_hooks_state(i: int) -> tuple[str, str, str, list[str]]:
    variants = [
        (
            _wrap(
                """
                import { useState } from "react";

                export function app(props: { title: string }) {
                  const [count, setCount] = useState(0);
                  return <div>{props.title}{count}</div>;
                }
                """
            ),
            ["useState", "react-import"],
        ),
        (
            _wrap(
                """
                import { useState } from "react";

                export function app(props: { title: string }) {
                  const [status, setStatus] = useState("idle");
                  return <div>{props.title}{status}</div>;
                }
                """
            ),
            ["useState", "react-import"],
        ),
    ]
    src, tags = variants[i % len(variants)]
    return f"pilot_{i:03d}_hooks_state.tsx", src, "hooks_state", tags


def family_hooks_effect(i: int) -> tuple[str, str, str, list[str]]:
    deps = ["[]", "[count]", "[props.id]"]
    dep = deps[i % 3]
    body = "setCount(0);" if "count" in dep else "setLabel('go');"
    src = _wrap(
        f"""
        import {{ useState, useEffect }} from "react";

        export function app(props: {{ id: string; title: string }}) {{
          const [count, setCount] = useState(0);
          const [label, setLabel] = useState("ready");
          useEffect(() => {{
            {body}
          }}, {dep});
          return <div>{{props.title}}{{count}}{{label}}</div>;
        }}
        """
    )
    tags = ["useEffect", "useState"]
    if dep == "[props.id]":
        tags.append("effect-prop-deps")
    return f"pilot_{i:03d}_hooks_effect.tsx", src, "hooks_effect", tags


def family_hooks_ref(i: int) -> tuple[str, str, str, list[str]]:
    src = _wrap(
        """
        import { useRef } from "react";

        export function app(props: { label: string }) {
          const node = useRef(null);
          return <div ref={node}>{props.label}</div>;
        }
        """
    )
    return f"pilot_{i:03d}_hooks_ref.tsx", src, "hooks_ref", ["useRef", "jsx-ref-attr"]


def family_helpers(i: int) -> tuple[str, str, str, list[str]]:
    helpers = [
        (
            _wrap(
                """
                function add(a: number, b: number): number { return a + b; }
                export function app(props: { x: number }) {
                  const y = add(props.x, 1);
                  return <div>{y}</div>;
                }
                """
            ),
            ["local-helper", "def"],
        ),
        (
            _wrap(
                """
                const double = (n: number): number => n * 2;
                export function app(props: { x: number }) {
                  return <div>{double(props.x)}</div>;
                }
                """
            ),
            ["local-helper", "arrow"],
        ),
        (
            _wrap(
                """
                function greet(name: string): string { return `Hi ${name}!`; }
                export function app(props: { name: string }) {
                  return <div>{greet(props.name)}</div>;
                }
                """
            ),
            ["local-helper", "template-literal"],
        ),
    ]
    src, tags = helpers[i % len(helpers)]
    return f"pilot_{i:03d}_helpers.tsx", src, "helpers", tags


def family_control_flow(i: int) -> tuple[str, str, str, list[str]]:
    flows = [
        (
            _wrap(
                """
                export function app(props: { n: number }) {
                  let s = "";
                  if (props.n > 0) { s = "pos"; }
                  return <div>{s}</div>;
                }
                """
            ),
            ["if-stmt"],
        ),
        (
            _wrap(
                """
                export function app(props: { items: string[] }) {
                  let out = "";
                  for (const x of props.items) { out = out + x; }
                  return <div>{out}</div>;
                }
                """
            ),
            ["for-of"],
        ),
        (
            _wrap(
                """
                export function app(props: { limit: number }) {
                  let i = 0;
                  while (i < props.limit) { i = i + 1; }
                  return <div>{i}</div>;
                }
                """
            ),
            ["while"],
        ),
    ]
    src, tags = flows[i % len(flows)]
    return f"pilot_{i:03d}_control_flow.tsx", src, "control_flow", tags


def family_ts_types(i: int) -> tuple[str, str, str, list[str]]:
    variants = [
        (
            _wrap(
                """
                export function app(props: { value: string | number }) {
                  return <div>{props.value}</div>;
                }
                """
            ),
            ["union-type"],
        ),
        (
            _wrap(
                """
                export function app(props: { tags: Array<string> }) {
                  return <div>{props.tags.join(",")}</div>;
                }
                """
            ),
            ["generic-array"],
        ),
        (
            _wrap(
                """
                interface AppProps { name: string; count: number }
                export function app(props: AppProps) {
                  return <div>{props.name}{props.count}</div>;
                }
                """
            ),
            ["interface-props", "external-props-alias"],
        ),
        (
            _wrap(
                """
                export function app(props: { pair: [string, number] }) {
                  return <div>{props.pair[0]}{props.pair[1]}</div>;
                }
                """
            ),
            ["tuple-type"],
        ),
    ]
    src, tags = variants[i % len(variants)]
    return f"pilot_{i:03d}_ts_types.tsx", src, "ts_types", tags


def family_interop(i: int) -> tuple[str, str, str, list[str]]:
    variants = [
        (
            _wrap(
                """
                import { useMemo } from "react";
                export function app(props: { items: string[] }) {
                  const sorted = useMemo(() => [...props.items], [props.items]);
                  return <div>{sorted.join("-")}</div>;
                }
                """
            ),
            ["useMemo-interop"],
        ),
        (
            _wrap(
                """
                import { useCallback } from "react";
                export function app(props: { n: number }) {
                  const bump = useCallback(() => props.n + 1, [props.n]);
                  return <div>{bump()}</div>;
                }
                """
            ),
            ["useCallback-interop"],
        ),
        (
            _wrap(
                """
                import { clsx } from "clsx";
                export function app(props: { name: string }) {
                  const c = clsx("x", props.name);
                  return <div className={c}>{props.name}</div>;
                }
                """
            ),
            ["npm-import"],
        ),
    ]
    src, tags = variants[i % len(variants)]
    return f"pilot_{i:03d}_interop.tsx", src, "interop", tags


def family_wrappers(i: int) -> tuple[str, str, str, list[str]]:
    variants = [
        (
            _wrap(
                """
                type ButtonProps = { title: string };
                export const app: React.FC<ButtonProps> = (props) => <h1>{props.title}</h1>;
                """
            ),
            ["react-fc"],
        ),
        (
            _wrap(
                """
                import { memo } from "react";
                type ItemProps = { label: string };
                export const app = memo((props: ItemProps) => <span>{props.label}</span>);
                """
            ),
            ["memo"],
        ),
        (
            _wrap(
                """
                import { forwardRef } from "react";
                type InputProps = { value: string };
                export const app = forwardRef<HTMLInputElement, InputProps>((props, ref) => (
                  <input ref={ref} value={props.value} />
                ));
                """
            ),
            ["forwardRef"],
        ),
    ]
    src, tags = variants[i % len(variants)]
    return f"pilot_{i:03d}_wrappers.tsx", src, "wrappers", tags


def family_native_idioms(i: int) -> tuple[str, str, str, list[str]]:
    src = _wrap(
        """
        function build(items: string[]): string[] {
          const out: string[] = [];
          for (const x of items) { out.push(x); }
          return out;
        }
        export function app(props: { items: string[] }) {
          const xs = props.items.map(x => x.toUpperCase());
          const d = { a: 1 };
          const v = d.a;
          return <div>{build(xs).join(",")}{v}</div>;
        }
        """
    )
    return f"pilot_{i:03d}_native_idioms.tsx", src, "native_idioms", [
        "list-append", "comprehension", "dict-access", "join"
    ]


def family_minimal_tsx(i: int) -> tuple[str, str, str, list[str]]:
    """JS-style patterns in .tsx (inline types required for reviewed conversion)."""
    variants = [
        (
            _wrap(
                """
                export const app = (props: { title: string; body: string }) => (
                  <section><h2>{props.title}</h2><p>{props.body}</p></section>
                );
                """
            ),
            ["arrow-export", "props-bag"],
        ),
        (
            _wrap(
                """
                const label = (name: string): string => "Name: " + name;
                export function app(props: { name: string }) {
                  return <div>{label(props.name)}</div>;
                }
                """
            ),
            ["const-helper", "props-bag"],
        ),
        (
            _wrap(
                """
                export function app(props: { items: string[] }) {
                  return <div>{props.items.map(x => <span key={x}>{x}</span>)}</div>;
                }
                """
            ),
            ["inline-map", "props-bag"],
        ),
        (
            _wrap(
                """
                export const app = (props: { active: boolean }) => (
                  <div>{props.active ? "on" : "off"}</div>
                );
                """
            ),
            ["arrow-export", "jsx-ternary"],
        ),
        (
            _wrap(
                """
                function wrap(text: string): string { return "[" + text + "]"; }
                export const app = (props: { msg: string }) => <p>{wrap(props.msg)}</p>;
                """
            ),
            ["arrow-export", "local-helper"],
        ),
    ]
    src, tags = variants[i % len(variants)]
    return f"pilot_{i:03d}_minimal_tsx.tsx", src, "minimal_tsx", tags


def family_ts_only(i: int) -> tuple[str, str, str, list[str]]:
    src = _wrap(
        """
        type Msg = { text: string };
        export function app(props: Msg) {
          return <div>{props.text}</div>;
        }
        """
    )
    return f"pilot_{i:03d}_ts_only.tsx", src, "ts_only", ["ts", "type-alias"]


# Allocation: 100 records across families (counts sum to 100)
FAMILY_PLAN: list[tuple[str, int]] = [
    ("basic_props", 8),
    ("destructure", 8),
    ("jsx_attrs", 7),
    ("jsx_conditionals", 7),
    ("jsx_lists", 7),
    ("hooks_state", 7),
    ("hooks_effect", 6),
    ("hooks_ref", 5),
    ("helpers", 7),
    ("control_flow", 7),
    ("ts_types", 7),
    ("interop", 6),
    ("wrappers", 5),
    ("native_idioms", 5),
    ("minimal_tsx", 5),
    ("ts_only", 3),
]

FAMILY_FUNCS = {
    "basic_props": family_basic_props,
    "destructure": family_destructure,
    "jsx_attrs": family_jsx_attrs,
    "jsx_conditionals": family_jsx_conditionals,
    "jsx_lists": family_jsx_lists,
    "hooks_state": family_hooks_state,
    "hooks_effect": family_hooks_effect,
    "hooks_ref": family_hooks_ref,
    "helpers": family_helpers,
    "control_flow": family_control_flow,
    "ts_types": family_ts_types,
    "interop": family_interop,
    "wrappers": family_wrappers,
    "native_idioms": family_native_idioms,
    "minimal_tsx": family_minimal_tsx,
    "ts_only": family_ts_only,
}


def generate_records() -> list[dict]:
    records: list[dict] = []
    idx = 1
    for family, count in FAMILY_PLAN:
        fn = FAMILY_FUNCS[family]
        for j in range(count):
            path, source, fam, tags = fn(j)
            # Renumber globally for stable ordering
            ext = path.rsplit(".", 1)[-1]
            stem = path.split("_", 2)[-1].rsplit(".", 1)[0]
            rel = f"pilot_{idx:03d}_{stem}.{ext}"
            lang = {"tsx": "tsx", "jsx": "jsx", "js": "js", "ts": "ts"}[ext]
            records.append({
                "index": idx,
                "path": rel,
                "source": source,
                "language": lang,
                "family": fam,
                "rule_tags": tags,
                "template_seed": PILOT_SEED + idx,
            })
            idx += 1
    assert len(records) == 100, f"expected 100 records, got {len(records)}"
    return records


def write_corpus(out_dir: str, manifest_path: str | None) -> list[dict]:
    os.makedirs(out_dir, exist_ok=True)
    # Clear prior pilot_*.tsx|jsx|js|ts files
    for name in os.listdir(out_dir):
        if name.startswith("pilot_") and name.endswith((".tsx", ".jsx", ".js", ".ts")):
            os.remove(os.path.join(out_dir, name))

    records = generate_records()
    manifest_entries = []
    for rec in records:
        out_path = os.path.join(out_dir, rec["path"])
        with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(rec["source"])
        entry = {
            "record_id": _record_id(rec["source"]),
            "schema_version": 1,
            "source": {"path": rec["path"], "bytes": len(rec["source"].encode("utf-8"))},
            "language": rec["language"],
            "family": rec["family"],
            "rule_tags": rec["rule_tags"],
            "source_sha256": _sha256(rec["source"]),
            "license": LICENSE,
            "lineage": {
                "template_seed": rec["template_seed"],
                "generator": GENERATOR_VERSION,
            },
            "split": "unassigned",
        }
        manifest_entries.append(entry)

    manifest = {
        "schema_version": 1,
        "pilot": "A",
        "target_count": 100,
        "generator": GENERATOR_VERSION,
        "pilot_seed": PILOT_SEED,
        "rule_set_version": RULE_SET_VERSION,
        "license": LICENSE,
        "records": manifest_entries,
    }
    if manifest_path:
        os.makedirs(os.path.dirname(manifest_path) or ".", exist_ok=True)
        with open(manifest_path, "w", encoding="utf-8") as fh:
            json.dump(manifest, fh, indent=2, sort_keys=True)
            fh.write("\n")
    return manifest_entries


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate js2jac 100-component pilot corpus")
    parser.add_argument("--out", default=DEFAULT_OUT, help="Output directory for source files")
    parser.add_argument(
        "--manifest",
        default=os.path.join(os.path.dirname(__file__), "pilot_manifest.json"),
        help="Manifest JSON path",
    )
    args = parser.parse_args()
    entries = write_corpus(args.out, args.manifest)
    print(f"Wrote {len(entries)} pilot sources to {args.out}")
    print(f"Manifest: {args.manifest}")


if __name__ == "__main__":
    main()
