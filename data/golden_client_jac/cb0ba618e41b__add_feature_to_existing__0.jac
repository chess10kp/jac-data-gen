enum HttpStatus: int { OK = 200, NOT_FOUND = 404, SERVER_ERROR = 500, UNAUTHORIZED = 401 }
enum Tag: str { OPEN = "open", CLOSE = "close" }

def get_status(description: str) -> HttpStatus by llm();
def get_tag(description: str) -> Tag by llm();
