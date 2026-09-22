"""Return the metadata filter represented as either None (no filter),
    or a dictionary with at most two keys: 'additional' and 'excluded',
    which contain either a list of metadata names, or the string 'all'"""
def metadata_filter_as_dict(metadata_config: Any) -> object {
    if (metadata_config is None) {
        return {};
    }
    if (metadata_config is True) {
        return {'additional': 'all'};
    }
    if (metadata_config is False) {
        return {'excluded': 'all'};
    }
    if isinstance(metadata_config, `dict) {
        assert (`set(metadata_config) <= `set(['additional', 'excluded']));
        return metadata_config;
    }
    metadata_keys = metadata_config.split(',');
    metadata_config = {};
    for key in metadata_keys {
        key = key.strip();
        if key.startswith('-') {
            metadata_config.setdefault('excluded', []).append(key[1:].strip());
        } elif key.startswith('+') {
            metadata_config.setdefault('additional', []).append(key[1:].strip());
        } else {
            metadata_config.setdefault('additional', []).append(key);
        }
    }
    for section in metadata_config {
        if ('all' in metadata_config[section]) {
            metadata_config[section] = 'all';
        } else {
            metadata_config[section] = [
                key
                for key in metadata_config[section]
                if key
            ];
        }
    }
    return metadata_config;
}