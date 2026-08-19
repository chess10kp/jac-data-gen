def InitWindow(width: int, height: int, title: str) {
    print(f"Opening {width}x{height} window: {title}");
}

def WindowShouldClose() -> bool {
    return True;
}

def BeginDrawing() {}
def EndDrawing() {}
def ClearBackground(color: int) {}

def DrawText(text: str, x: int, y: int, font_size: int, color: int) {
    print(f"[{x},{y}] {text}");
}

def CloseWindow() {
    print("Window closed");
}

with entry {
    InitWindow(800, 450, "Jac + raylib");
    while not WindowShouldClose() {
        BeginDrawing();
        ClearBackground(0);
        DrawText("Hello from Jac", 190, 200, 20, 16777215);
        EndDrawing();
    }
    CloseWindow();
}
