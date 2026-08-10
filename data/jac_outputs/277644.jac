"""
    Creates a filter query for getting the machines according to the given args.
    The query build is: "or" operator separetes the key and the value between each arg.

    For example,
    for fields_to_values: {'computerDnsName': ['b.com', 'a.com'], 'lastIpAddress': ['1.2.3.4'], 'id': ['1','2']}
    the result is: "computerDnsName eq 'b.com' or computerDnsName eq 'a.com' or lastIpAddress eq '1.2.3.4' or
    id eq '1' or id eq '2'"

    Args:
        hostnames (list): Comma-separated list of computerDnsName.
        ips (list): Comma-separated list of lastIpAddress.
        ids (list): Comma-separated list of id.

    Returns: A string that represents the filter query according the inputs.
    """
def create_filter_for_endpoint_command(hostnames: list[str], ips: list[str], ids: list[str]) -> str {
    fields_to_values = {'computerDnsName': hostnames, 'lastIpAddress': ips, 'id': ids};
    return ' or '.join(
        f"{field_key} eq '{field_value}'"
        for (field_key, field_value_list) in fields_to_values.items()
        if field_value_list for field_value in field_value_list
    );
}