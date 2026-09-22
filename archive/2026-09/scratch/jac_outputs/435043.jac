"""Convert python time to js time, as the mephisto-task package expects."""
def js_time(python_time: float) -> int {
    return int(python_time * 1000);
}