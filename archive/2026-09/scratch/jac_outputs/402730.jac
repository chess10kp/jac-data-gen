"""Reacrete message from N columns (N = columns_to_build_from)"""
def assemble_message_from_columns(columns_to_build_from: list[str]) -> str {
    max_column_len = max([len(c) for c in columns_to_build_from]);
    text = "";
    for i in range(0, max_column_len) {
        for c in columns_to_build_from {
            try {
                text += c[i];
            } except Exception {
                text += "";
            }
        }
    }
    return text;
}