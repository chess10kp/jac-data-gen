"""Removes >>> and ... prompts from code blocks in examples."""
def strip_code_prompts(rst_string: str) -> str {
    return rst_string.replace('&gt;&gt;&gt; ', '').replace('&gt;&gt;&gt;\n', '\n').replace('\n...', '\n');
}