"""Check server status"""
def info() -> tuple[dict[str, bool | str], int] {
    return ({"success": True, "message": "Aquila X is running healthy"}, 200);
}