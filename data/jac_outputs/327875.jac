"""
    Build the URL for an experiment to be published to.
    """
def build_experiment_url(base_url: str) -> str {
    '/'.join([base_url, 'experiment'])
}