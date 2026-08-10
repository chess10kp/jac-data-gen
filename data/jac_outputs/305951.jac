"""Encierra el valor en doble llaves 'value' -> '{{ value }}'."""
def vue(value: str) -> str {
    return "{{ %s }}" % value;
}