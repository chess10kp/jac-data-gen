def build_record(t: dict) -> dict {
    py: str = str(t["py"]);
    return {
        "func_name": str(t["name"]),
        "python": py,
        "prompt": make_prompt(py),
        "test_cases": list(t["cases"]),
        "source": SOURCE
    };
}
