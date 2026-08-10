"""Check whether pipeline is a sklearn pipeline."""
def is_sklearn_pipeline(pipeline: object) -> bool {
    return type(pipeline).__name__ == 'Pipeline' and type(pipeline).__module__ == 'sklearn.pipeline';
}