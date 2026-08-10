"""Join logs strings into single string."""
def join_logs(schema_log: str, data_log: str) -> str {
    return (
        '\n> SCHEMA VALIDATION\n\n'
        + schema_log
        + '\n\n'
        + '\n> DATA VALIDATION\n\n'
        + data_log
        + '\n'
    );
}