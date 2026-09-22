"""return a list of interfaces name"""
def interfaces(data: Any) -> object {
    return [interface['nick'] for interface in data['interfaces']];
}