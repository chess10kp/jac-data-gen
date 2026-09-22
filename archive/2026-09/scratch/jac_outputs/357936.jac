"""Return parsed id and arguments from build spec."""
def parse_spec(spec: dict | tuple | list | str) -> tuple[str, dict] {
    if isinstance(spec, dict) {
        return (spec['type'], spec.get('args', {}));
    }
    if isinstance(spec, (tuple, list)) and isinstance(spec[0], str) {
        return (spec[0], {} if len(spec) < 2 else spec[1]);
    }
    if isinstance(spec, str) {
        return (spec, {});
    }
    raise ValueError('Invalid build spec: {}'.format(spec));
}