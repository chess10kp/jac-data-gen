#!/usr/bin/env bun
/**
 * Fast decl-level wall probe over the EXISTING 203-record dataset jsonl (no repo
 * cloning). Parses each record's `js`, runs the real convert bridge fail-open,
 * and tallies skipReasons + per-record kept/dropped decl counts. Also classifies
 * every skip by *why* the whole declaration sank so we can see how much a
 * statement-level fail-open would recover.
 *
 * Usage: bun dataset_probe.mjs
 */
import { createRequire } from "module";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

import { convertEnvelope, PROTOCOL_VERSION } from
  "/home/jac/repos/jac_llm_data/jaseci/jac/jaclang/compiler/js2jac/convert_bridge.mjs";

const JS2JAC = "/home/jac/repos/jac_llm_data/jaseci/jac/jaclang/compiler/js2jac";
const DATASET = "/home/jac/repos/jac_llm_data/scripts/js2jac_dataset/js2jac_dataset.jsonl";

function loadParser() {
  const vendorRoot = path.join(JS2JAC, "vendor", "babel_parser");
  const req = createRequire(path.join(vendorRoot, "package.json"));
  return req("@babel/parser");
}
const parser = loadParser();

function langOf(p) {
  if (p.endsWith(".tsx")) return "tsx";
  if (p.endsWith(".ts")) return "ts";
  if (p.endsWith(".jsx")) return "jsx";
  return "js";
}
function plugins(lang) {
  const p = ["estree"];
  if (lang === "jsx" || lang === "tsx") p.push("jsx");
  if (lang === "ts" || lang === "tsx") p.push("typescript");
  return p;
}

const recs = fs.readFileSync(DATASET, "utf8").trim().split("\n").map((l) => JSON.parse(l));
const skipReasons = {};
const stmtDrops = {};
let filesTotal = 0, filesClean = 0, filesPartial = 0, filesNoDecl = 0, parseFail = 0;
let keptDecls = 0, droppedDecls = 0, stmtDropCount = 0, filesWithStmtDrop = 0;

for (const r of recs) {
  filesTotal++;
  const lang = langOf(r.path);
  let ast;
  try {
    ast = parser.parse(r.js, { sourceType: "unambiguous", plugins: plugins(lang), ranges: true, errorRecovery: false });
  } catch { parseFail++; continue; }
  const stmtFailOpen = process.env.STMT !== "0";
  const res = convertEnvelope({ protocolVersion: PROTOCOL_VERSION, path: r.path, ast, failOpen: true, stmtFailOpen });
  const reasons = res.skipReasons || {};
  for (const k of Object.keys(reasons)) skipReasons[k] = (skipReasons[k] || 0) + reasons[k];
  keptDecls += res.keptCount || 0;
  droppedDecls += res.droppedCount || 0;
  const sd = res.stmtDrops || {};
  for (const k of Object.keys(sd)) stmtDrops[k] = (stmtDrops[k] || 0) + sd[k];
  if (res.stmtDropCount) { stmtDropCount += res.stmtDropCount; filesWithStmtDrop++; }
  if (res.ok) {
    if (Object.keys(reasons).length) filesPartial++; else filesClean++;
  } else filesNoDecl++;
}

const sortHist = (h) => Object.entries(h).sort((a, b) => b[1] - a[1]);
console.log(JSON.stringify({
  files_total: filesTotal, files_clean: filesClean, files_partial: filesPartial,
  files_no_decl: filesNoDecl, parse_fail: parseFail,
  kept_decls: keptDecls, dropped_decls: droppedDecls,
  stmt_drop_count: stmtDropCount, files_with_stmt_drop: filesWithStmtDrop,
  stmt_drops: sortHist(stmtDrops),
  decl_walls: sortHist(skipReasons),
}, null, 1));
