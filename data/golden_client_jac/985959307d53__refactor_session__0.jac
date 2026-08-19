def _output_tail(out: str) -> str {
    trimmed = out.strip();
    lines = trimmed.split("\n");
    tail = lines[-8:];
    return "\n".join(tail);
}
