"""Converts a yaml list (volumes, configs etc) into a python dict

    :yaml_list: list of a yaml containing colon separated entries
    :return: python dict
    """
def yaml_list_to_dict(yaml_list: Any) -> object {
    return {i.split(":")[0]: i.split(":")[1] for i in yaml_list};
}