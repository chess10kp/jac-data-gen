#!/usr/bin/env bun
// Differential-oracle runner: stdin {code, entry, cases} -> stdout {results}.
// Executes the ORIGINAL JS/TS function on each case's args and locks the actual
// return value as ground truth. The model never states expectations — it only
// invents inputs, so hallucinated oracles are structurally impossible.
//
// TS is handled by writing a temp module and importing it (bun transpiles).
//
// stdin:  {"code": "<fn source>", "entry": "name", "cases": [{"args": [..]}, ..]}
// stdout: {"results": [{"i":0,"ok":true,"value":<json>},
//                      {"i":1,"ok":false,"error":"..."}, ..]}
import fs from "fs";
import os from "os";
import path from "path";

const input = JSON.parse(fs.readFileSync(0, "utf8"));

function serialize(v) {
  if (v === undefined) return { t: "undefined" };
  if (v === null) return { t: "null" };
  if (typeof v === "number") {
    if (Number.isNaN(v)) return { t: "nan" };
    if (!Number.isFinite(v)) return { t: "inf", sign: v > 0 ? 1 : -1 };
    return { t: "num", v };
  }
  if (typeof v === "boolean") return { t: "bool", v };
  if (typeof v === "string") return { t: "str", v };
  if (Array.isArray(v)) return { t: "arr", v: v.map(serialize) };
  if (typeof v === "object") {
    const o = {};
    for (const k of Object.keys(v).sort()) o[k] = serialize(v[k]);
    return { t: "obj", v: o };
  }
  return { t: "opaque", s: String(v) };
}

function fail(msg) {
  process.stdout.write(JSON.stringify({ ok: false, error: msg, results: [] }));
  process.exit(0);
}

const ext = /\binterface\b|\btype\s+\w+\s*=|:\s*(string|number|boolean)\b/.test(input.code)
  ? ".ts" : ".js";
const tmp = path.join(os.tmpdir(), `diffcase_${process.pid}_${Math.random().toString(36).slice(2)}${ext}`);
fs.writeFileSync(tmp, input.code +
  `\n;globalThis.__diff_entry = (typeof ${input.entry} !== "undefined") ? ${input.entry} : undefined;\n`);

try {
  const mod = await import(tmp);
  const fn = globalThis.__diff_entry ?? mod.default ?? mod[input.entry];
  if (typeof fn !== "function") fail(`entry ${input.entry} not a function`);
  const results = [];
  for (const c of input.cases) {
    const i = c.i;
    try {
      const out = fn(...c.args);
      JSON.stringify(out);                       // force lazy evaluation
      results.push({ i, ok: true, value: serialize(out) });
    } catch (e) {
      results.push({ i, ok: false, error: String(e && e.message || e).slice(0, 200) });
    }
  }
  process.stdout.write(JSON.stringify({ ok: true, results }));
} catch (e) {
  fail(String(e && e.message || e).slice(0, 300));
} finally {
  try { fs.unlinkSync(tmp); } catch {}
}
