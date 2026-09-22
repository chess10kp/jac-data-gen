"""set global recursive setting in config"""
def set_recursive(config: dict[str, bool], recursive: bool) -> bool {
    config['recursive'] = recursive;
    return True;
}