"""End to end: deploy/jacpi.sh drives real pi against a fake OpenAI-compatible
model that makes one jac_ast_edit call, then replies. Checks what the model
actually received (system prompt, tools, tool result) and that the session
log's jac-harness-snapshot entry matches it. Skipped when `pi` is missing.

Set JACPI_E2E_DUMP=<dir> to keep the captured requests and session log.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest

from conftest import ROOT, SAMPLE

pytestmark = pytest.mark.skipif(shutil.which("pi") is None, reason="pi not installed")

DEPLOY_TOOLS = ["read", "bash", "write", "jac_ast_search", "jac_ast_edit"]
EDIT_ARGS = {"path": "f.jac", "operations": [
    {"action": "add_statement", "target": "function", "name": "add_two", "newCode": 'q: int = "s";'}]}


def fake_model(requests: list[dict]):
    """Chat-completions SSE server: tool call first, plain reply once a tool result is present."""
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            requests.append(body)
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            base = {"id": "x", "object": "chat.completion.chunk", "model": "fake", "created": 0}
            if not any(m.get("role") == "tool" for m in body.get("messages", [])):
                call = {"index": 0, "id": "call_1", "type": "function",
                        "function": {"name": "jac_ast_edit", "arguments": json.dumps(EDIT_ARGS)}}
                chunks = [{"role": "assistant", "tool_calls": [call]}, None]
                finish = "tool_calls"
            else:
                chunks = [{"role": "assistant", "content": "done"}, None]
                finish = "stop"
            for delta in chunks:
                choice = {"index": 0, "delta": delta or {}, "finish_reason": None if delta else finish}
                self.wfile.write(f"data: {json.dumps({**base, 'choices': [choice]})}\n\n".encode())
            self.wfile.write(b"data: [DONE]\n\n")

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def test_deploy_profile_end_to_end(tmp_path):
    requests: list[dict] = []
    server = fake_model(requests)
    agent = tmp_path / "agent"
    agent.mkdir()
    (agent / "models.json").write_text(json.dumps({"providers": {"fake": {
        "baseUrl": f"http://127.0.0.1:{server.server_port}/v1", "api": "openai-completions", "apiKey": "x",
        "compat": {"supportsDeveloperRole": False, "supportsReasoningEffort": False},
        "models": [{"id": "fake-model"}]}}}))
    proj = tmp_path / "proj"
    proj.mkdir()
    (proj / "f.jac").write_text(SAMPLE)
    (proj / "AGENTS.md").write_text("project instructions that the deploy profile must NOT load\n")
    sessions = tmp_path / "sessions"
    env = {**os.environ, "JAC_AST_EDIT_CHECK": "1", "JACPI_AGENT_DIR": str(agent), "JACPI_SOURCE_AGENT_DIR": str(tmp_path / "none"),
           "JAC_AST_EDIT_CACHE_DIR": str(tmp_path / "cache")}
    try:
        proc = subprocess.run(
            [str(ROOT / "deploy" / "jacpi.sh"), "--model", "fake/fake-model", "--session-dir", str(sessions),
             "-p", "make add_two store a string"],
            cwd=proj, env=env, capture_output=True, text=True, timeout=240)
    finally:
        server.shutdown()
    assert proc.returncode == 0, proc.stderr[-2000:]
    assert proc.stdout.strip().endswith("done")
    assert len(requests) == 2

    first, second = requests
    system = (ROOT / "deploy" / "SYSTEM.md").read_text()
    sent_prompt = first["messages"][0]["content"]
    assert sent_prompt == f"{system}\nCurrent working directory: {proj}\n"
    assert [t["function"]["name"] for t in first["tools"]] == DEPLOY_TOOLS

    tool_msg = next(m for m in second["messages"] if m["role"] == "tool")
    result = tool_msg["content"] if isinstance(tool_msg["content"], str) else tool_msg["content"][0]["text"]
    assert result.startswith("add_statement ok (lines +1)\n[f.jac:28-32 function add_two]\n")
    if shutil.which("jac"):
        assert "jac check: 1 new error (file has 2 total):\nerror[E1001] f.jac:31:5:" in result

    entries = [json.loads(line) for f in sessions.glob("*.jsonl") for line in f.read_text().splitlines()]
    snaps = [e["data"] for e in entries if e.get("type") == "custom" and e.get("customType") == "jac-harness-snapshot"]
    assert len(snaps) == 1
    assert snaps[0]["systemPrompt"] == sent_prompt
    sent_tools = {t["function"]["name"]: t["function"] for t in first["tools"]}
    assert [t["name"] for t in snaps[0]["tools"]] == DEPLOY_TOOLS
    for t in snaps[0]["tools"]:
        assert t["description"] == sent_tools[t["name"]]["description"]
        assert t["parameters"] == sent_tools[t["name"]]["parameters"]

    dump = os.environ.get("JACPI_E2E_DUMP")
    if dump:
        out = Path(dump)
        out.mkdir(parents=True, exist_ok=True)
        (out / "requests.json").write_text(json.dumps(requests, indent=1))
        (out / "tool_result.txt").write_text(result)
        for f in sessions.glob("*.jsonl"):
            shutil.copy(f, out / f.name)
