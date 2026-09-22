"""Socket to glsl type."""
def glsl_type(socket_type: str) -> str {
    if socket_type in ('RGB', 'RGBA', 'VECTOR') {
        return 'vec3';
    }
    return 'float';
}