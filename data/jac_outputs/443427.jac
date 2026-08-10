"""
    Convert command line options to transfer dictionary

    Args:
        server_from_str (str): counter to iterate over environment variables
        server_to_str (str): Environment variables from os.environ
        folders_str (str)

    Returns:
        dict: transfer dictionary
    """
def get_transfer_dict_cmd(
    server_from_str: Any, server_to_str: Any, folders_str: Any
) -> object {
    server_from_lst = server_from_str.split(";");
    server_to_lst = server_to_str.split(";");
    folders_dict = {
        el[0]: el[1] for el in [s.split(":") for s in folders_str.split(";")]
    };
    return {
        "server_from": {
            "host": server_from_lst[0],
            "username": server_from_lst[1],
            "password": server_from_lst[2]
        },
        "server_to": {
            "host": server_to_lst[0],
            "username": server_to_lst[1],
            "password": server_to_lst[2]
        },
        "dirs": folders_dict
    };
}