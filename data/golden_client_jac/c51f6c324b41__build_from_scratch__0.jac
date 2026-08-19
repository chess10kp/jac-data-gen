enum HttpStatus: int { OK = 200, NOT_FOUND = 404 }

with entry {
    print(HttpStatus.OK == 200);   # True -- compare directly
}
