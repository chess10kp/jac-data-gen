"""Generate URDF visual element XML from geometry, material, and origin fragments."""
def gen_urdf_visual(geom: str, material: str, origin: str) -> str {
    return '<visual>{0}{1}{2}</visual>'.format(geom, material, origin);
}