"""Create flavor(s)."""
def create(name: str, vcpus: int, ram: int, disk: int, **kwargs: int | str | bool) -> tuple[str, dict] {
    url = '/flavors';
    req = {'flavor': {'name': name, 'vcpus': vcpus, 'ram': ram, 'disk': disk}};
    req['flavor'].update(kwargs);
    return (url, {'json': req});
}