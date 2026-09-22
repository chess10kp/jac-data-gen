"""
Map labels from scenes in biwi and crowds dataset to path-aligned scene labels.
"""
def __map_scene_labels_biwi_crowds__(_labels: list[str] | None = None) -> list[str] {
    (eth_label, hotel_label, univ_label, zara_label) = (
        'biwi_eth',
        'biwi_hotel',
        'crowds_univ',
        'crowds_zara'
    );
    if not _labels {
        return [eth_label, hotel_label, univ_label, zara_label];
    }
    scene_labels = [];
    for label in _labels {
        label_low = label.lower();
        if 'eth' in label_low {
            scene_labels.append(eth_label);
        } elif 'hotel' in label_low {
            scene_labels.append(hotel_label);
        } elif 'univ' in label_low {
            scene_labels.append(univ_label);
        } elif 'zara' in label_low {
            scene_labels.append(zara_label);
        } else {
            raise Exception(
                f'Received an invalid scene label for a biwi/crowds scene - {label}'
            );
        }
    }
    return scene_labels;
}