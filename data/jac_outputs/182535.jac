"""convert seconds to minute display"""
def to_minutes(chrono: Any) -> object {
    return f"{int((float(chrono) / 60))}:{round(
        (float(chrono) - ((float(chrono) // 60) * 60)), 2
    )}";
}