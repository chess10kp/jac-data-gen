#!/usr/bin/env bun
// Structural-fidelity signature of a JS/TS source, for the js2jac fidelity gate.
// stdin: {js, path}  ->  stdout: {ok, exports, funcs, strings, callees, counts}
// Same babel parser + plugin selection as holeconvert.mjs so the signature sees
// exactly what the converter saw.
import { createRequire } from "module";
import path from "path";
import fs from "fs";
const JS2JAC = "/home/jac/repos/jac_llm_data/jaseci/jac/jaclang/compiler/js2jac";
const req = createRequire(path.join(JS2JAC, "vendor", "babel_parser", "package.json"));
const parser = req("@babel/parser");

function langOf(p){if(p.endsWith(".tsx"))return"tsx";if(p.endsWith(".ts"))return"ts";if(p.endsWith(".jsx"))return"jsx";return"js";}
function plug(l){const p=["estree"];if(l==="jsx"||l==="tsx")p.push("jsx");if(l==="ts"||l==="tsx")p.push("typescript");return p;}

const input = JSON.parse(fs.readFileSync(0, "utf8"));
let ast;
try {
  ast = parser.parse(input.js, { sourceType: "unambiguous", plugins: plug(langOf(input.path)), ranges: true, errorRecovery: true });
} catch (e) {
  process.stdout.write(JSON.stringify({ ok:false, error:"parse:"+e.message })); process.exit(0);
}

const exportsSet = new Set();   // names a consumer can import (what MUST survive)
const funcs = [];               // {name, arity}
const strings = new Set();      // semantic string literals (not import sources)
const callees = new Set();      // called function / method names
const counts = { branches:0, loops:0, returns:0, strings:0, numbers:0, jsx:0 };

function declNames(node){
  // names bound by a declaration node (function/class/var)
  const out=[];
  if(!node) return out;
  if(node.id&&node.id.name) out.push(node.id.name);
  if(node.type==="VariableDeclaration") for(const d of node.declarations) if(d.id&&d.id.name) out.push(d.id.name);
  return out;
}
function fnArity(node){ return (node.params||[]).length; }
function recordFn(name,node){ if(name) funcs.push({name, arity:fnArity(node)}); }

function walk(node, parent){
  if(!node||typeof node!=="object") return;
  if(Array.isArray(node)){ for(const c of node) walk(c,parent); return; }
  if(typeof node.type!=="string") return;
  switch(node.type){
    case "ExportNamedDeclaration": {
      // skip TYPE-only exports (interfaces/type aliases / `export type {...}`) —
      // they have no runtime existence, so the converter dropping them is not loss
      const TYPE=new Set(["TSInterfaceDeclaration","TSTypeAliasDeclaration"]);
      const d=node.declaration;
      if(d && !TYPE.has(d.type)) for(const n of declNames(d)) exportsSet.add(n);
      if(node.exportKind!=="type")
        for(const s of (node.specifiers||[]))
          if(s.exportKind!=="type" && s.exported && s.exported.name) exportsSet.add(s.exported.name);
      break; }
    case "ExportDefaultDeclaration": {
      const d=node.declaration;
      if(d&&d.id&&d.id.name) exportsSet.add(d.id.name); else exportsSet.add("default");
      break; }
    case "FunctionDeclaration": recordFn(node.id&&node.id.name, node); break;
    case "VariableDeclarator":
      if(node.id&&node.id.name&&node.init&&(node.init.type==="ArrowFunctionExpression"||node.init.type==="FunctionExpression"))
        recordFn(node.id.name, node.init);
      break;
    case "ImportDeclaration": return; // skip: import sources are not semantic strings
    case "StringLiteral": case "Literal": {   // estree plugin normalizes literals to "Literal"
      const v=node.value;
      if(typeof v==="string"){
        counts.strings++;
        if(v.trim().length>=2 && !(parent&&(parent.type==="ImportDeclaration"||parent.type==="ExportNamedDeclaration"||parent.type==="ExportAllDeclaration")))
          strings.add(v.trim());
      } else if(typeof v==="number"){ counts.numbers++; }
      break; }
    case "TemplateElement":
      if(node.value&&node.value.cooked&&node.value.cooked.trim().length>=2) strings.add(node.value.cooked.trim());
      break;
    case "NumericLiteral": counts.numbers++; break;
    case "CallExpression": {
      const c=node.callee;
      if(c){ if(c.type==="Identifier") callees.add(c.name);
             else if(c.type==="MemberExpression"&&c.property&&c.property.name) callees.add(c.property.name); }
      break; }
    case "IfStatement": case "ConditionalExpression": case "SwitchCase": counts.branches++; break;
    case "ForStatement": case "ForInStatement": case "ForOfStatement": case "WhileStatement": case "DoWhileStatement": counts.loops++; break;
    case "ReturnStatement": counts.returns++; break;
    case "JSXElement": case "JSXFragment": counts.jsx++; break;
  }
  for(const k in node){
    if(k==="loc"||k==="range"||k==="start"||k==="end"||k==="leadingComments"||k==="trailingComments") continue;
    const v=node[k];
    if(v&&typeof v==="object") walk(v, node);
  }
}
walk(ast, null);

process.stdout.write(JSON.stringify({
  ok:true,
  exports:[...exportsSet],
  funcs,
  strings:[...strings],
  callees:[...callees],
  counts,
}));
