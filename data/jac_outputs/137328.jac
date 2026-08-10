"""Returns time in the format H:MM:SS
    @rtype:  str
    @return: Time in the format H:MM:SS"""
def __splitTime(sec: Any) -> object {
    (min, sec) = divmod(sec, 60);
    (hour, min) = divmod(min, 60);
    return (hour, min, sec);
}