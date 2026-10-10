/**
 * pi extension: `jac_ast_search` + `jac_ast_edit` — AST-native search and
 * editing for Jac (.jac) files.
 *
 * Backed by tree-sitter: the Jac grammar is compiled into a local Python
 * binding and the engine lives in ../python/jac_ast_edit.py. Edits locate
 * symbols by {target, name} in the parse tree and splice byte spans; batches
 * are atomic and rejected if the new source would introduce syntax errors.
 * The engine also renders the model-facing result text (changed-code view,
 * new `jac check` errors, search listings), so this file stays a thin shell.
 */
import { withFileMutationQueue } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { stat } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Type } from "typebox";

const PKG_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const VENV_PYTHON = resolve(PKG_ROOT, ".venv", "bin", "python");
const ENGINE = resolve(PKG_ROOT, "python", "jac_ast_edit.py");

/** String enum as a plain JSON-schema `enum` (provider-portable, like pi-ai's StringEnum). */
function stringEnum<T extends string>(values: readonly T[], description: string) {
  return Type.Unsafe<T>({ type: "string", enum: [...values], description });
}

// The model-facing surface. The engine still accepts older action names and
// kind aliases (archetype, method, property, add_method, add_enum, ...), but
// only these are advertised, so trained models see one way to do each thing.
const EDIT_ACTIONS = [
  "set_body", "add_statement", "replace_in_body", "replace",
  "add_member", "add_declaration",
  "rename", "remove", "set_initializer", "set_type", "set_return_type",
  "add_parameter", "remove_parameter", "set_extends",
  "add_import", "remove_import", "organize_imports",
] as const;

const SYMBOL_KINDS = [
  "obj", "node", "edge", "walker", "class", "function", "ability", "impl",
  "has", "enum", "member", "glob", "type", "test", "import", "code",
] as const;

const SEARCH_MODES = ["symbols", "outline", "text", "files"] as const;

/** Engine call budget: two `jac check` runs (before/after) plus the edit. */
const CHECK_TIMEOUT_S = Number(process.env.JAC_AST_EDIT_CHECK_TIMEOUT ?? "30") || 30;
const EDIT_TIMEOUT_MS = (2 * CHECK_TIMEOUT_S + 30) * 1000;

async function ensureEngine(): Promise<void> {
  try {
    await stat(VENV_PYTHON);
  } catch {
    throw new Error(
      `jac_ast_edit: python binding not built. Run:\n` +
        `  cd ${PKG_ROOT} && python3 -m venv .venv && .venv/bin/pip install "tree-sitter>=0.25,<0.27" setuptools && .venv/bin/pip install -e ./python`,
    );
  }
}

interface EngineResult {
  ok?: boolean;
  error?: { code: string; message: string; suggestions?: string[] };
  report?: string;
  applied?: { op: number; action: string; ok: boolean }[];
  changed?: boolean;
  newDiagnostics?: number;
  checkSeconds?: number;
  scannedFiles?: number;
  truncated?: boolean;
}

function runEngine(args: string[], stdinBody: string, timeoutMs: number): Promise<EngineResult> {
  return new Promise((resolvePromise, rejectPromise) => {
    const child = spawn(VENV_PYTHON, [ENGINE, ...args], { stdio: ["pipe", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      child.kill("SIGKILL");
      rejectPromise(new Error(`jac_ast_edit engine timed out after ${String(timeoutMs)}ms`));
    }, timeoutMs);
    child.stdout.on("data", (d: Buffer) => (stdout += d.toString()));
    child.stderr.on("data", (d: Buffer) => (stderr += d.toString()));
    child.on("error", (err) => {
      clearTimeout(timer);
      rejectPromise(err);
    });
    child.on("close", () => {
      clearTimeout(timer);
      try {
        resolvePromise(JSON.parse(stdout) as EngineResult);
      } catch {
        rejectPromise(
          new Error(`jac_ast_edit engine returned non-JSON output: ${stdout.slice(0, 400)} ${stderr.slice(0, 400)}`),
        );
      }
    });
    child.stdin.write(stdinBody);
    child.stdin.end();
  });
}

function engineError(result: EngineResult): Error {
  const err = result.error ?? { code: "engine_error", message: "unknown engine error" };
  const sug = err.suggestions?.length ? "\n" + err.suggestions.join("\n") : "";
  return new Error(`${err.code}: ${err.message}${sug}`);
}

const searchSchema = Type.Object({
  query: Type.Optional(
    Type.String({ description: "Name (symbols), literal text (text), or path substring (files)." }),
  ),
  mode: Type.Optional(stringEnum(SEARCH_MODES, "symbols (default) | outline | text | files.")),
  root: Type.Optional(Type.String({ description: "Directory or file to search. Default: current directory." })),
  kind: Type.Optional(stringEnum(SYMBOL_KINDS, "Only symbols of this kind (symbols mode).")),
  pathGlob: Type.Optional(Type.String({ description: "Path glob, e.g. 'src/**/*.jac' or '**/*.py' (text mode)." })),
  exact: Type.Optional(Type.Boolean({ description: "Exact name match (symbols mode)." })),
  limit: Type.Optional(Type.Number({ description: "Max results. Default 100 (text: 50), max 500." })),
});

const operationSchema = Type.Object({
  action: stringEnum(EDIT_ACTIONS, "The edit to apply."),
  target: Type.Optional(stringEnum(SYMBOL_KINDS, "Kind of the symbol to edit.")),
  name: Type.Optional(Type.String({ description: "Symbol name: 'walk', 'Card', 'Card.label' (member or impl)." })),
  value: Type.Optional(
    Type.String({ description: "Short argument: new name, expression, type, anchor text, import line or module." }),
  ),
  valueEnd: Type.Optional(Type.String({ description: "replace_in_body: end anchor of the span to replace." })),
  newCode: Type.Optional(Type.String({ description: "Code to insert; see the action list." })),
  index: Type.Optional(Type.Number({ description: "Which match, when several symbols match (see error)." })),
});

const EDIT_DESCRIPTION = [
  "Edit a .jac file by symbol name. {path, operations:[...]}: operations apply in order as one atomic batch; " +
    "if the result would not parse, nothing is written. Find names first with jac_ast_search (mode 'outline', root=<file>).",
  "Actions:",
  "- set_body: newCode = new body statements, without braces.",
  "- add_statement: newCode is appended at the end of the body (after any return).",
  "- replace_in_body: value = unique anchor text in the body (+ optional valueEnd = end anchor); newCode replaces that span.",
  "- replace: newCode = the whole new symbol.",
  "- add_member: newCode = a field ('has x: int = 0;') or a full method; target = the archetype.",
  "- add_declaration: newCode = a full top-level declaration (def, obj, node, edge, walker, enum, impl, test, glob, type).",
  "- rename (value = new name), remove, set_initializer (value = expression), set_type / set_return_type (value = type), " +
    "add_parameter (value = 'x: int = 0'), remove_parameter (value = name), set_extends (value = 'Base, Mixin').",
  "- add_import (value = full import line; merges into an existing 'import from' of the module), " +
    "remove_import (value = module, newCode = one item), organize_imports.",
  "If several symbols match, the error lists them with index=N. " +
    "The result shows the changed code and any NEW jac check errors; fix those errors next.",
].join("\n");

const SEARCH_CMDS = new Set(["rg", "grep", "egrep", "fgrep", "ag", "ack", "find", "fd"]);
/** grep-likes that only filter another command's output when they read a pipe. */
const FILTER_CMDS = new Set(["rg", "grep", "egrep", "fgrep", "ag", "ack"]);

/** True if a bash command searches files (blocked: use jac_ast_search). Text
 * filters on a pipe (`jac guide x | grep foo`) are allowed; so is anything quoted. */
export function isShellSearch(command: string): boolean {
  const unquoted = command.replace(/'[^']*'|"(?:[^"\\]|\\.)*"/g, "''");
  const parts = unquoted.split(/(\|\||&&|;|\n|\||\$\(|`|\()/);
  let prev = "";
  for (let i = 0; i < parts.length; i += 2) {
    const words = parts[i].trim().split(/\s+/).filter((w) => !/^\w+=/.test(w) && w !== "sudo" && w !== "command");
    let cmd = words[0] ?? "";
    if (cmd === "xargs") cmd = words.find((w, j) => j > 0 && !w.startsWith("-")) ?? "";
    const piped = prev === "|" && words[0] !== "xargs";
    if (cmd === "git" && words[1] === "grep") return true;
    if (SEARCH_CMDS.has(cmd) && !(piped && FILTER_CMDS.has(cmd))) return true;
    prev = parts[i + 1] ?? "";
  }
  return false;
}

/** Session-entry type holding the exact system prompt + active tool schemas
 * the model saw — what trajectory converters need to rebuild SFT rows. */
const HARNESS_SNAPSHOT_TYPE = "jac-harness-snapshot";

export default function (pi: ExtensionAPI) {
  // Record the system prompt + active tool schemas into the session log
  // (a custom entry: persisted, never sent to the LLM) whenever they change,
  // so recorded sessions can be converted to SFT rows that match deploy time.
  let lastSnapshotHash = "";
  pi.on("session_start", () => {
    lastSnapshotHash = "";
  });
  pi.on("before_agent_start", (event) => {
    if (process.env.JAC_AST_EDIT_NO_SNAPSHOT) return undefined;
    const active = new Set(pi.getActiveTools());
    const tools = pi
      .getAllTools()
      .filter((t) => active.has(t.name))
      .map((t) => ({ name: t.name, description: t.description, parameters: t.parameters }));
    const snapshot = { systemPrompt: event.systemPrompt, tools };
    const hash = createHash("sha256").update(JSON.stringify(snapshot)).digest("hex").slice(0, 16);
    if (hash !== lastSnapshotHash) {
      lastSnapshotHash = hash;
      pi.appendEntry(HARNESS_SNAPSHOT_TYPE, { hash, ...snapshot });
    }
    return undefined;
  });

  pi.on("tool_call", (event) => {
    if (event.toolName !== "bash") return undefined;
    const command = String((event.input as { command?: unknown }).command ?? "");
    if (isShellSearch(command)) {
      return {
        block: true,
        reason:
          "Shell search (grep/rg/find/fd/ag/ack/git grep) is disabled. Use jac_ast_search: " +
          "mode 'text' for text inside files, 'symbols' for declarations, 'files' to list .jac files.",
      };
    }
    return undefined;
  });

  pi.registerTool({
    name: "jac_ast_search",
    label: "Jac AST Search",
    description:
      "Search the project without grep. Modes: 'symbols' (default) finds Jac declarations whose name contains query; " +
      "'outline' lists every symbol in the files under root (root = a .jac file for one file); " +
      "'text' finds literal text inside .jac files (case-insensitive unless query has capitals) and names the enclosing symbol, " +
      "pathGlob like '**/*.py' searches other files; 'files' lists .jac files. Results give path:line.",
    promptSnippet: "Search Jac symbols, outlines and text (use instead of grep/find)",
    parameters: searchSchema,
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const rootPath = resolve(ctx.cwd, (params.root ?? ".").replace(/^@/, ""));
      await ensureEngine();
      const result = await runEngine(["search", rootPath], JSON.stringify({ ...params, cwd: ctx.cwd }), 60_000);
      if (result.error) throw engineError(result);
      return {
        content: [{ type: "text", text: result.report ?? "" }],
        details: { scannedFiles: result.scannedFiles, truncated: result.truncated },
        isError: false,
      } as const;
    },
  });

  pi.registerTool({
    name: "jac_ast_edit",
    label: "Jac AST Edit",
    description: EDIT_DESCRIPTION,
    promptSnippet: "Edit .jac files by symbol name (atomic, parse-checked, reports new jac check errors)",
    parameters: Type.Object({
      path: Type.String({ description: "The .jac file to edit." }),
      operations: Type.Array(operationSchema, { description: "Edits, applied in order, all or nothing." }),
    }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const rawPath = params.path.replace(/^@/, "");
      const filePath = resolve(ctx.cwd, rawPath);
      if (!filePath.endsWith(".jac")) {
        throw new Error(`jac_ast_edit only edits .jac files (got ${rawPath}); use write for other files.`);
      }
      if (!params.operations || params.operations.length === 0) {
        throw new Error("operations must contain at least one edit.");
      }
      try {
        await stat(filePath);
      } catch {
        throw new Error(`${rawPath} does not exist; create new files with write.`);
      }
      await ensureEngine();

      return withFileMutationQueue(filePath, async () => {
        const result = await runEngine(
          ["edit", filePath],
          JSON.stringify({ operations: params.operations, displayPath: rawPath, cwd: ctx.cwd }),
          EDIT_TIMEOUT_MS,
        );
        if (result.error) throw engineError(result);
        return {
          content: [{ type: "text", text: result.report ?? "" }],
          details: {
            path: filePath,
            applied: result.applied,
            newDiagnostics: result.newDiagnostics,
            checkSeconds: result.checkSeconds,
          },
          isError: false,
        } as const;
      });
    },
  });
}
