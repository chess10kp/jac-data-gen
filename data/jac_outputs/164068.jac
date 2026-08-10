"""
    Setting up the desired path directories for each type of file to be converted
    :return:
    """
def path_directories(path_dirs: dict) -> object {
    trips_tuple = (
        path_dirs['trips_path'],
        path_dirs['trips_csv_folder'],
        path_dirs['trips_sheet_tab'],
        (path_dirs['trips_create_parent_table'] == "True"),
        path_dirs['trips_name']
    );
    finances_tuple = (
        path_dirs['finances_path'],
        path_dirs['finances_csv_folder'],
        path_dirs['finances_sheet_tab'],
        (path_dirs['finances_create_parent_table'] == "True"),
        path_dirs['finances_name']
    );
    path_dict = {
        trips_tuple: path_dirs['trips_name'],
        finances_tuple: path_dirs['finances_name']
    };
    return path_dict;
}