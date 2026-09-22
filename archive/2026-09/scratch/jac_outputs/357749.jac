"""Generate fake URLs for the given layer and unit."""
def generate_urls(layer: Any, unit: Any, k: Any) -> object {
    return [f'https://images.com/{layer}/{unit}/im-{index}.png' for index in range(k)];
}