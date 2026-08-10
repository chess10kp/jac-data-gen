"""Converts a process dict to a name vec."""
def dict_to_namevec(process_dict: dict[str, str]) -> str {
    name_vec = '';
    name_vec += process_dict['type'];
    if 'environment' in process_dict {
        name_vec += process_dict['environment'];
    }
    if 'dataset' in process_dict {
        name_vec += process_dict['dataset'];
    }
    name_vec += process_dict['experiment'];
    return name_vec;
}