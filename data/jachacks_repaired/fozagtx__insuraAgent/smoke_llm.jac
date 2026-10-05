# Minimal byLLM smoke test.
# Run:  bash run_demo.sh-smoke   (or just `jac run smoke_llm.jac` with env loaded)

import os;
import time;
import from byllm.llm { Model }

def _pick() -> Model {
    if os.environ.get("FEATHERLESS_API_KEY") {
        model_id = os.environ.get("APPEAL_MODEL", "openai/Qwen/Qwen2.5-14B-Instruct");
        return Model(
            model_name=model_id,
            api_key=os.environ.get("FEATHERLESS_API_KEY", "")
        );
    }
    if os.environ.get("ANTHROPIC_API_KEY") {
        return Model(model_name="claude-sonnet-4-20250514");
    }
    if os.environ.get("GEMINI_API_KEY") {
        return Model(model_name="gemini/gemini-2.5-flash");
    }
    if os.environ.get("OPENAI_API_KEY") {
        return Model(model_name="gpt-4o-mini");
    }
    raise Exception("No API key");
}

glob llm = _pick();

def classify(text: str) -> str by llm();

with entry {
    print(f"Model: {os.environ.get('APPEAL_MODEL', 'openai/Qwen/Qwen2.5-14B-Instruct')}");
    t0 = time.time();
    result = classify("Classify this in one word: a dog barking loudly at the mailman");
    t1 = time.time();
    print(f"LLM classification: {result}");
    print(f"Elapsed: {t1 - t0:.2f}s");
}
