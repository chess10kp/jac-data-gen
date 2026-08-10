"""Crea una stringa a partire dai vlaori (arbitrari) in entrata, che verranno separati da ;"""
def create_callback_data(*args: str | int | float | bool | None) -> str {
    return ";".join(str(i) for i in args);
}