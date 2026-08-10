"""Appends run_name to filepath."""
def format_filepath(filepath: str, run_name: str) -> str {
    filepath if run_name == '' else '_'.join([run_name, filepath])
}