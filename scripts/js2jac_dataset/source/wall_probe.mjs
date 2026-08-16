#!/usr/bin/env bun
/**
 * Decl-level wall probe for js2jac at the current fail-open yield.
 *
 * Clones each candidate repo, walks its project-root source files, and runs the
 * REAL convert bridge in-process (failOpen=true) per file. Aggregates:
 *   - skipReasons: per-declaration blocker codes across all files that partially
 *     converted (the fail-open decl-level walls — what still sinks declarations
 *     at 7.2% keep).
 *   - fileFail:    the top diagnostic code for files that produced NO convertible
 *     declaration at all (whole-file walls).
 *
 * Usage: bun wall_probe.mjs [--limit N]
 */
import { createRequire } from "module";
import { fileURLToPath } from "url";
import { execFileSync } from "child_process";
import fs from "fs";
import os from "os";
import path from "path";

import { convertEnvelope, PROTOCOL_VERSION } from
  "/home/jac/repos/jac_llm_data/jaseci/jac/jaclang/compiler/js2jac/convert_bridge.mjs";

const JS2JAC = "/home/jac/repos/jac_llm_data/jaseci/jac/jaclang/compiler/js2jac";
const HERE = path.join(fileURLToPath(new URL(".", import.meta.url)));
const CAND = path.join(HERE, "candidates.jsonl");
const SRC_HINTS = ["src", "app", "client", "frontend", "packages", "."];

const argLimit = (() => {
  const i = process.argv.indexOf("--limit");
  return i >= 0 ? parseInt(process.argv[i + 1], 10) : 40;
})();
const argProfile = (() => {
  const i = process.argv.indexOf("--profile");
  return i >= 0 ? process.argv[i + 1] : "react";
})();

// Stack profile: same profiles.json as discover.py/harvest.py. Match semantics
// are mirrored from profiles.py -- keep the two in sync.
const PROFILES = JSON.parse(fs.readFileSync(path.join(HERE, "profiles.json"), "utf8"));
const profile = PROFILES[argProfile];
if (!profile) {
  console.error(`unknown profile ${argProfile}; have: ${Object.keys(PROFILES).join(", ")}`);
  process.exit(2);
}
const depMatch = (dep, pat) => (pat.endsWith("*") ? dep.startsWith(pat.slice(0, -1)) : dep === pat);
function matchDeps(deps) {
  for (const pat of profile.deny_any || [])
    if (deps.some((d) => depMatch(d, pat))) return false;
  for (const group of profile.require_groups || [])
    if (!deps.some((d) => group.some((pat) => depMatch(d, pat)))) return false;
  return true;
}
const PATH_EXCLUDE = profile.path_exclude || [];
const pathExcluded = (rel) => PATH_EXCLUDE.some((p) => rel.replace(/\\/g, "/").includes(p));

function loadParser() {
  const vendorRoot = path.join(JS2JAC, "vendor", "babel_parser");
  const req = createRequire(path.join(vendorRoot, "package.json"));
  return req("@babel/parser");
}
const parser = loadParser();

function langOf(file) {
  if (file.endsWith(".tsx")) return "tsx";
  if (file.endsWith(".ts")) return "ts";
  if (file.endsWith(".jsx")) return "jsx";
  if (file.endsWith(".js")) return "js";
  return null;
}
function plugins(lang) {
  const p = ["estree"];
  if (lang === "jsx" || lang === "tsx") p.push("jsx");
  if (lang === "ts" || lang === "tsx") p.push("typescript");
  return p;
}

function sh(cmd, args, opts = {}) {
  try { return { ok: true, out: execFileSync(cmd, args, { encoding: "utf8", timeout: 180000, ...opts }) }; }
  catch (e) { return { ok: false, out: String(e.stderr || e.message || e) }; }
}

function passesProfile(repo) {
  const pj = path.join(repo, "package.json");
  if (!fs.existsSync(pj)) return false;
  try {
    const d = JSON.parse(fs.readFileSync(pj, "utf8"));
    const deps = Object.keys({ ...(d.dependencies || {}), ...(d.devDependencies || {}) });
    return matchDeps(deps);
  } catch { return false; }
}
function pickRoot(repo) {
  for (const h of SRC_HINTS) {
    const d = h === "." ? repo : path.join(repo, h);
    if (fs.existsSync(d) && fs.statSync(d).isDirectory() && hasTsx(d)) return d;
  }
  return repo;
}
function hasTsx(dir) {
  for (const f of walk(dir)) if (f.endsWith(".tsx")) return true;
  return false;
}
function* walk(dir) {
  let ents;
  try { ents = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of ents) {
    if (e.name === "node_modules" || e.name === "dist" || e.name === ".next" ||
        e.name === "build" || e.name.startsWith(".")) continue;
    const full = path.join(dir, e.name);
    if (e.isDirectory()) yield* walk(full);
    else yield full;
  }
}

const skipReasons = {};
const skipDetails = {};
const stmtDrops = {};
let stmtDropCount = 0, filesWithStmtDrop = 0, keptOff = 0, keptOn = 0;
const fileFail = {};
let filesTotal = 0, filesClean = 0, filesPartial = 0, filesNoDecl = 0, parseFail = 0;
let reposDone = 0, reposNoReact = 0;
let reExportTotal = 0, filesReExportOnly = 0, filesWithReExport = 0;

const cands = fs.readFileSync(CAND, "utf8").trim().split("\n")
  .map((l) => JSON.parse(l)).slice(0, argLimit);

for (const c of cands) {
  const dest = fs.mkdtempSync(path.join(os.tmpdir(), "wallprobe_"));
  const dir = path.join(dest, "r");
  const branch = c.default_branch || "main";
  let cl = sh("git", ["clone", "--depth", "1", "--branch", branch, "--single-branch", c.clone_url, dir]);
  if (!cl.ok) cl = sh("git", ["clone", "--depth", "1", "--single-branch", c.clone_url, dir]);
  if (!cl.ok) { fs.rmSync(dest, { recursive: true, force: true }); continue; }
  try {
    if (!passesProfile(dir)) { reposNoReact++; continue; }
    const root = pickRoot(dir);
    for (const file of walk(root)) {
      const lang = langOf(file);
      if (!lang) continue;
      if (file.endsWith(".d.ts")) continue;
      if (pathExcluded(path.relative(root, file))) continue;
      filesTotal++;
      let source;
      try { source = fs.readFileSync(file, "utf8"); } catch { continue; }
      let ast;
      try {
        ast = parser.parse(source, {
          sourceType: "unambiguous", plugins: plugins(lang),
          ranges: true, errorRecovery: false,
        });
      } catch { parseFail++; fileFail["E7102(parse)"] = (fileFail["E7102(parse)"] || 0) + 1; continue; }
      const rel = path.relative(root, file);
      // Dual-mode in one clone pass: statement fail-open OFF vs ON, to tally the
      // declarations statement-level fail-open newly recovers across real repos.
      const resOff = convertEnvelope({ protocolVersion: PROTOCOL_VERSION, path: rel, ast, failOpen: true, stmtFailOpen: false });
      const res = convertEnvelope({ protocolVersion: PROTOCOL_VERSION, path: rel, ast, failOpen: true, stmtFailOpen: true });
      keptOff += resOff.keptCount || 0;
      keptOn += res.keptCount || 0;
      const reasons = res.skipReasons || {};
      for (const k of Object.keys(reasons)) skipReasons[k] = (skipReasons[k] || 0) + reasons[k];
      const details = res.skipDetails || {};
      for (const k of Object.keys(details)) skipDetails[k] = (skipDetails[k] || 0) + details[k];
      const sd = res.stmtDrops || {};
      for (const k of Object.keys(sd)) stmtDrops[k] = (stmtDrops[k] || 0) + sd[k];
      if (res.stmtDropCount) { stmtDropCount += res.stmtDropCount; filesWithStmtDrop++; }
      if (res.reExportCount) {
        reExportTotal += res.reExportCount;
        filesWithReExport++;
        // A file that yields ZERO declarations but ok:true converts SOLELY on
        // its lowered re-exports — pure barrel recovered by this lever.
        if ((res.keptCount || 0) === 0) filesReExportOnly++;
      }
      if (res.ok) {
        if (Object.keys(reasons).length) filesPartial++; else filesClean++;
      } else {
        filesNoDecl++;
        // File yielded no convertible declaration. If it carries decl reasons,
        // those are already folded above; the terminal code (E7200 / empty
        // module / etc.) still tells us the whole-file wall shape.
        const code = (res.diagnostics && res.diagnostics[0] && res.diagnostics[0].code) || "unknown";
        fileFail[code] = (fileFail[code] || 0) + 1;
      }
    }
    reposDone++;
  } finally {
    fs.rmSync(dest, { recursive: true, force: true });
  }
  process.stderr.write(`[${reposDone}] ${c.full_name} files=${filesTotal}\n`);
}

const sortHist = (h) => Object.entries(h).sort((a, b) => b[1] - a[1]);
console.log(JSON.stringify({
  repos_done: reposDone, repos_no_react: reposNoReact,
  files_total: filesTotal, files_clean: filesClean,
  files_partial: filesPartial, files_no_decl: filesNoDecl, parse_fail: parseFail,
  kept_decls_stmt_off: keptOff, kept_decls_stmt_on: keptOn,
  stmt_drop_count: stmtDropCount, files_with_stmt_drop: filesWithStmtDrop,
  re_export_total: reExportTotal, files_with_reexport: filesWithReExport,
  files_reexport_only: filesReExportOnly,
  stmt_drops: sortHist(stmtDrops),
  decl_walls: sortHist(skipReasons),
  decl_wall_detail: sortHist(skipDetails).slice(0, 120),
  file_walls: sortHist(fileFail),
}, null, 1));
