obj CircleService {
    has name: str;
    def describe -> str;
}

impl CircleService.describe -> str {
    return f"Service: {self.name}";
}
