def step_b -> str { return "b"; }

glob llm = MockLLM(
    model_name="mockllm",
    ctx_window=1000,
    config={"outputs": [
        MockToolCall(tool=step_b, args={}),
        MockToolCall(tool=finish_tool, args={"final_output": "done"})
    ]}
);
