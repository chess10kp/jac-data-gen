"""Dedicated fuction to only count specific hosts"""
def count_hosts(meetings: dict[str, list[dict[str, str]]]) -> dict[str, int] {
    host_dict = dict();
    for item in meetings['items'] {
        if item['hostEmail'] not in host_dict {
            host_dict[item['hostEmail']] = 1;
        } else {
            host_dict[item['hostEmail']] += 1;
        }
    }
    return host_dict;
}