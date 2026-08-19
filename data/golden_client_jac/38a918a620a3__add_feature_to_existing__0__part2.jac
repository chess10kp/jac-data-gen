import from byllm.lib { MockLLM, MockToolCall }

def step_a -> str { return "a"; }
def step_b -> str { return "b"; }
def finish_tool(final_output: str) -> str { return final_output; }

glob llm = MockLLM(
    model_name="mockllm",
    ctx_window=1000,
    config={"outputs": [
        # (tool_call, usage) - triggers compaction at 85 % of 1000 tokens
        (MockToolCall(tool=step_a, args={}), {"prompt_tokens": 850, "total_tokens": 950}),
        MockToolCall(tool=step_b, args={}),
        MockToolCall(tool=finish_tool, args={"final_output": "done"})
    ]}
);
