enum HttpStatus: int { OK = 200, NOT_FOUND = 404 }
enum Tag: str { OPEN = "open", CLOSE = "close" }

with entry {
    print(HttpStatus.OK == 200);          # True -- compare directly
    print(isinstance(Tag.OPEN, str));     # True
    print(HttpStatus.OK + 1);             # 201 -- arithmetic works
}
