"""Converts a sense hat pixel picture to SVG format.
pixels is a list of 64 smaller lists of [R, G, B] pixels."""
def render_svg(pixels: list[list[int]]) -> str {
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80">';
    for y in range(8) {
        for x in range(8) {
            color = pixels[(y * 8) + x];
            if color[0] == 0 and color[1] == 0 and color[2] == 0 {
                continue;
            }
            svg += '<rect x="{x}" y="{y}" width="10" height="10" style="fill:rgb({r},{g},{b})" />'.format(
                x=(x * 10), y=(y * 10), r=color[0], g=color[1], b=color[2]
            );
        }
    }
    svg += '</svg>';
    return svg;
}