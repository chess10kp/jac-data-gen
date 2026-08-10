"""
    """
def get_colored_for_soi_columns(value_list: Any) -> object {
    list_output = [];
    if value_list {
        for each_ in value_list {
            dictionary = {};
            dictionary['if'] = {"column_id": each_};
            dictionary['backgroundColor'] = "#3D9970";
            dictionary['color'] = 'black';
            list_output.append(dictionary);
        }
        return list_output;
    } else {
        return None;
    }
}