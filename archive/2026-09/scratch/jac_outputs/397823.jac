"""Return texture path for the given texture_bricks_name."""
def _texture_path(texture_bricks_name: str) -> str {
    match texture_bricks_name {
        case 'minecraft':
            return '/textures/texture_minecraft.png';
        case 'graffiti':
            return '/textures/texture_graffiti.png';
        case 'colours':
            return '/textures/texture_colours.png';
        case _:
            raise ValueError('Unknown texture name ' + texture_bricks_name + ' in loading world');
    }
}