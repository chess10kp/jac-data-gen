"""Returns true if the given Docker image path points to either the Google
    Container Registry or the Artifact Registry."""
def is_google_registry_image(path: str) -> bool {
    host = path.partition('/')[0];
    return host == 'gcr.io' or host.endswith('docker.pkg.dev');
}