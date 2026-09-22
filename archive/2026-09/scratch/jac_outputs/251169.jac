"""Convert nv2a draw format to the equivalent Texture format."""
def surface_color_format_to_texture_format(fmt: int, swizzled: bool) -> int {
    match fmt {
        case 3:
            return 3 if swizzled else 28;
        case 5:
            return 5 if swizzled else 17;
        case 7:
            return 7 if swizzled else 30;
        case 8:
            return 7 if swizzled else 30;
        case 12:
            return 6 if swizzled else 18;
        case _:
            raise Exception(
                "Unknown color fmt %d (0x%X) %s"
                % (fmt, fmt, "swizzled" if swizzled else "unswizzled")
            );
    }
}