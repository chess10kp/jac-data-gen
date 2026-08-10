"""Wraps the value with Terraform interpolation syntax."""
def tf(value: str) -> str {
    return '${' + value + '}';
}