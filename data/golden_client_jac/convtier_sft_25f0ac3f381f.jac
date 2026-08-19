def keycode(code: str) -> int {
    match code {
        case "KeyW":
            return 87;
        case "KeyA":
            return 65;
        case "KeyS":
            return 83;
        case "KeyD":
            return 68;
        case "Space":
            return 32;
        case "ArrowUp":
            return 265;
        case "ArrowDown":
            return 264;
        case _:
            return 0;
    }
}

with entry {
    print(keycode('KeyW'));
}
