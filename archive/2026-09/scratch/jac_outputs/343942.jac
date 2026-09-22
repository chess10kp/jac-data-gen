"""
	Validates that a discovery config is valid for a specific service class
	"""
def validate_config(config: Any, service_class: Any) -> object {
    header = config.setdefault('header', {});
    if (service_class != header.get('service_class')) {
        raise Exception(
            (
                "Cannot store config hash of type %s in service class %s: %s"
                % (header.get('service_class'), service_class, config)
            )
        );
    }
    return config;
}