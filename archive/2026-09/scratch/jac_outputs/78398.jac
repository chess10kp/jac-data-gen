"""Map "1.0,2,0" => (1.0, 2.0)"""
def str2tuple(string: str, sep: str = ",") -> tuple[float, ...] {
    tuple(map(float, string.split(sep)))
}