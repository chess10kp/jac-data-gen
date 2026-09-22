"""
    Convert millisconds into a string in format mm:ss.ms
    """
def from_ms(time: int) -> str {
    minute = time // 60000;
    second = (time // 1000) - (minute * 60);
    millisecond = time - (minute * 60000) - (second * 1000);
    if (second < 10) {
        second = "0" + str(second);
    } else {
        second = str(second);
    }
    if (millisecond < 10) {
        millisecond = f"00{millisecond}";
    } elif (millisecond < 100) {
        millisecond = f"0{millisecond}";
    } else {
        millisecond = str(millisecond);
    }
    return f"{minute}:{second}.{millisecond}";
}