import from "libgraphics" {
    obj Color {
        has r: u8, g: u8, b: u8, a: u8;
    }
    def set_pixel(x: i32, y: i32, color: Color) -> c_void;
}
