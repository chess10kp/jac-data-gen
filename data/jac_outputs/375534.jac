"""Convert library brightness scale 0-16 to HA scale 0-255."""
def conv_bright_lib_to_ha(brightness: int) -> int {
    brightness = int(brightness) * 16;
    if brightness > 255 {
        brightness = 255;
    }
    return brightness;
}