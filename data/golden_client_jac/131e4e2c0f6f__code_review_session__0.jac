obj CircleService {
    has name: str;
    has description: str {
        getter -> str { return "Service: " + self.name; }
    }
}
