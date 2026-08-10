"""Transforms a json from the studio format to the vulcan format."""
def transform_json_from_studio_to_vulcan(studio_json: Any) -> object {
    vulcan_json = [];
    for studio_image in studio_json['images'] {
        vulcan_pred = {'outputs': [{'labels': {'discarded': [], 'predicted': []}}]};
        predicted = [];
        discarded = [];
        for metadata in ['location', 'data'] {
            if (metadata in studio_image) {
                vulcan_pred[metadata] = studio_image[metadata];
            }
        }
        for studio_pred in studio_image['annotated_regions'] {
            annotation = {
                'label_name': studio_pred['tags'][0],
                'score': studio_pred['score'],
                'threshold': studio_pred['threshold']
            };
            if (studio_pred['region_type'] == 'Box') {
                annotation['roi'] = {
                    'bbox': {
                        'xmin': studio_pred['region']['xmin'],
                        'xmax': studio_pred['region']['xmax'],
                        'ymin': studio_pred['region']['ymin'],
                        'ymax': studio_pred['region']['ymax']
                    }
                };
            }
            if (annotation['score'] >= annotation['threshold']) {
                predicted.append(annotation);
            } else {
                discarded.append(annotation);
            }
        }
        predicted = sorted(
            predicted, key=lambda (k: Any) { k['score']; }, reverse=True
        );
        discarded = sorted(
            discarded, key=lambda (k: Any) { k['score']; }, reverse=True
        );
        vulcan_pred['outputs'][0]['labels']['predicted'] = predicted;
        vulcan_pred['outputs'][0]['labels']['discarded'] = discarded;
        vulcan_json.append(vulcan_pred);
    }
    return vulcan_json;
}