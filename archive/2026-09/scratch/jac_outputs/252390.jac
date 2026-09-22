"""Generates the check dictionary to pass to consul of the form {'checks': []}"""
def generate_checks(container: str, address: str, check_ports: list[int]) -> dict[str, list[dict[str, str]]] {
    checks = {};
    checks['checks'] = [];
    for p in check_ports {
        checks['checks'].append(
            {
                'id': '{}-port{}'.format(container, p),
                'name': 'Check TCP port {}'.format(p),
                'tcp': '{}:{}'.format(address, p),
                'Interval': '30s',
                'timeout': '4s'
            }
        );
    }
    return checks;
}