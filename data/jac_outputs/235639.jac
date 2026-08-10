"""Convert types of values from specified JSON file."""
def convert_types(input_dict: Any) -> object {
    for key in input_dict.keys() {
        if (input_dict[key]['type'] == 'tuple') {
            input_dict[key]['type'] = 'list';
        }
        for el_key in ['type', 'element_type'] {
            if (el_key in input_dict[key].keys()) {
                input_dict[key][el_key] = eval(input_dict[key][el_key]);
            }
        }
    }
    for key in input_dict.keys() {
        if (
            ('default' in input_dict[key].keys())
            and (input_dict[key]['default'] is not None)
        ) {
            if ('element_type' in input_dict[key].keys()) {
                if (input_dict[key]['type'] == `list) {
                    for i in range(len(input_dict[key]['default'])) {
                        input_dict[key]['default'][i] = input_dict[key]['element_type'](
                            input_dict[key]['default'][i]
                        );
                    }
                }
            } else {
                input_dict[key]['default'] = input_dict[key]['type'](
                    input_dict[key]['default']
                );
            }
        }
    }
    return input_dict;
}