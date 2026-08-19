import from "./libraylib.so" {
    def InitWindow(width: i32, height: i32, title: str) -> None;
    def WindowShouldClose() -> bool;
    def rlVertex3f(x: f32, y: f32, z: f32) -> None;
    def rlColor4ub(r: u8, g: u8, b: u8, a: u8) -> None;
    def CloseWindow() -> None;
}

with entry {
    InitWindow(800, 600, "jac native");
    while not WindowShouldClose() {
        rlColor4ub(230, 41, 55, 255);
        rlVertex3f(-0.5, -0.5, 0.0);
    }
    CloseWindow();
}
