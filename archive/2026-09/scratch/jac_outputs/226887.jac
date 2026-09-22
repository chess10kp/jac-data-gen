"""Creates reference to a property of a given resource."""
def get_ref(name: str, prop: str = 'selfLink') -> str {
    return '$(ref.{}.{})'.format(name, prop);
}