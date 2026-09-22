"""Process one argument for _redact_keys."""
def _redact_arg(arg: str, s3_config: dict[str, dict[str, dict[str, str]]]) -> str {
    for config in s3_config.values() {
        for mode in ['read', 'write'] {
            if mode in config {
                for name in ['access_key', 'secret_key'] {
                    key = config[mode].get(name);
                    if key and (arg == key or arg.endswith('=' + key)) {
                        return arg[:-len(key)] + 'REDACTED';
                    }
                }
            }
        }
    }
    return arg;
}