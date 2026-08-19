obj Dog {
    has secret: str = "",
        trick: str = "";

    def rename() -> None {
        self.secret = "oops";
    }

    def train() -> None {
        self.trick = "sit";
    }
}
