# probe_featherless.jac — minimal Featherless compatibility probe.
#
# Run BEFORE the full demo if you've never tried this project on
# Featherless before:
#
#   export FEATHERLESS_API_KEY=fl-...
#   jac run probe_featherless.jac
#
# What it tests, in order, with increasing schema complexity:
#   1. Plain str return       — establishes baseline connectivity
#   2. Enum return            — exercises a small constrained schema
#   3. Typed `obj` return     — exercises `response_format: json_schema`
#                               (this is the surface that vLLM / Featherless
#                               historically reject on some models)
#
# If steps 1-2 pass but step 3 fails, see FEATHERLESS_COMPAT.md for the
# 5-minute refactor to switch tool returns from typed obj → str + JSON parse.

import os;
import from byllm.llm { Model }
import from models { DenialReason, PolicyClause }

glob llm = Model(
    model_name=os.environ.get(
        "FEATHERLESS_PROBE_MODEL",
        "featherless_ai/meta-llama/Meta-Llama-3.1-70B-Instruct"
    )
);

# ---- Test 1: plain str (no schema constraint) --------------------------
def echo_one_word(text: str) -> str by llm();

# ---- Test 2: enum return (small constrained schema) --------------------
"""
Classify the denial reason from this denial sentence. Be conservative:
pick OTHER if it does not clearly fit one of the named categories.
"""
def probe_enum(denial_text: str) -> DenialReason by llm();

# ---- Test 3: typed obj return (full response_format: json_schema) ------
"""
Pretend you are reading an insurance policy and return ONE plausible
clause. Make up reasonable content — this is a connectivity probe, not
an analysis task. Fill every field.
"""
def probe_typed_obj(topic: str) -> PolicyClause by llm();


def _ok(label: str, value: any) {
    print(f"  PASS  {label}");
    print(f"        -> {value}");
}

def _fail(label: str, err: any) {
    print(f"  FAIL  {label}");
    print(f"        -> {err}");
}


with entry {
    have_key = (os.environ.get("FEATHERLESS_API_KEY", "") != ""
                or os.environ.get("FEATHERLESS_AI_API_KEY", "") != "");
    if not have_key {
        print("ERROR: set FEATHERLESS_API_KEY (or FEATHERLESS_AI_API_KEY) first.");
        print("  export FEATHERLESS_API_KEY=fl-...");
    } else {
        print("=" * 60);
        print("FEATHERLESS COMPATIBILITY PROBE");
        print("=" * 60);
        print(f"Model: {llm.model_name}");
        print("");

        # --- 1. str baseline ---
        try {
            r = echo_one_word("Reply with the single word: pong");
            _ok("1/3 plain str return", r);
        } except Exception as e {
            _fail("1/3 plain str return", e);
            print("");
            print("  Connectivity is broken. Check your API key and model name.");
            print("  Not a schema problem — stop here and fix auth first.");
        }

        # --- 2. enum (small schema) ---
        try {
            r = probe_enum("Claim denied because no prior authorization was obtained.");
            _ok("2/3 enum return (DenialReason)", r);
        } except Exception as e {
            _fail("2/3 enum return (DenialReason)", e);
        }

        # --- 3. typed obj (full json_schema) ---
        try {
            r = probe_typed_obj("network adequacy");
            _ok("3/3 typed obj return (PolicyClause)", r);
            print("");
            print("=" * 60);
            print("RESULT: Featherless accepts typed obj returns on this model.");
            print("No refactor needed. Run the full demo:");
            print("  jac run main.jac");
            print("=" * 60);
        } except Exception as e {
            _fail("3/3 typed obj return (PolicyClause)", e);
            print("");
            print("=" * 60);
            print("RESULT: typed obj returns are rejected.");
            print("Apply the patch in FEATHERLESS_COMPAT.md (5 minutes), or");
            print("switch to a stronger Featherless model via:");
            print("  export FEATHERLESS_PROBE_MODEL=featherless_ai/Qwen/Qwen2.5-72B-Instruct");
            print("and re-run this probe.");
            print("=" * 60);
        }
    }
}
