"""Create a provenance record describing the diagnostic data and plots."""
def get_provenance_record(caption: str, ancestors: list[str]) -> dict[str, str | list[str]] {
    return {
        'caption': caption,
        'domains': ['reg'],
        'authors': [
            'kalverla_peter',
            'smeets_stef',
            'brunner_lukas',
            'camphuijsen_jaro'
        ],
        'references': ['brunner2019', 'lorenz2018', 'knutti2017'],
        'ancestors': ancestors
    };
}