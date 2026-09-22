"""
    Add weights to postcode sector

    """
def add_weights_to_postcode_sector(postcode_sectors: Any, weights: Any) -> object {
    output = [];
    for postcode_sector in postcode_sectors {
        pcd_id = postcode_sector['properties']['id'].replace(' ', '');
        for weight in weights {
            weight_id = weight['id'].replace(' ', '');
            if (pcd_id == weight_id) {
                output.append(
                    {
                        'type': postcode_sector['type'],
                        'geometry': postcode_sector['geometry'],
                        'properties': {
                            'id': pcd_id,
                            'lad': postcode_sector['properties']['lad'],
                            'population_weight': weight['population'],
                            'area_km2': (
                                postcode_sector['properties']['area'] / 1000000.0
                            )
                        }
                    }
                );
            }
        }
    }
    return output;
}