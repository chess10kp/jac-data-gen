"""
        makes flat list for update values.
        :param columns_to_query_lst:
        :param columns_to_update_lst:
        :param query_values_dict_lst:
        :return values: list of user-given values for multirow query with first params to
                query and then params to update. E.g ['col2query1','col2update1','col2query2','col2update2']
        """
def get_values_multicol(
    columns_to_query_lst: Any, columns_to_update_lst: Any, query_values_dict_lst: Any
) -> object {
    values = [];
    for dict_row in query_values_dict_lst {
        for col in columns_to_query_lst {
            values.append(dict_row['where'][col]);
        }
        for col in columns_to_update_lst {
            values.append(dict_row['update'][col]);
        }
    }
    return values;
}