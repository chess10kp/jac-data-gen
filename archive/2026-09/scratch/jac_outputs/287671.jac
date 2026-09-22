"""Creates a list with deleted device at IMC.
Only added to the list, if the operation was successful."""
def create_ip_list_from_operator_log(json_response_operator_log: list[dict[str, str]]) -> list[str] {
    deleted_ips = list();
    for entry in json_response_operator_log {
        print(entry);
        if entry["resultStr"] == "Success" {
            start_index = entry["description"].rindex("(") + 1;
            end_index = entry["description"].rindex(")");
            deleted_ips.append(entry["description"][start_index:end_index]);
        }
    }
    return deleted_ips;
}