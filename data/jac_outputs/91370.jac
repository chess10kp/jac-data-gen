"""Shows explore network button after enrichment is done."""
def show_explore_network_btn(enrichment_results: object) -> dict[str, str] {
    return {'display': 'inline-block'} if enrichment_results else {'display': 'none'};
}