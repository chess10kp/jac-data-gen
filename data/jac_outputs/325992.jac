"""Extracts the name of a configured pipeline."""
def extract_pipeline_name(pipeline: dict[str, object]) -> str {
    return list(pipeline.keys())[0];
}