class Dog {
    has secret: str = "";
    has trick: str = "";

    def rename() -> None {
        self.secret = "oops";
    }

    def train() -> None {
        self.trick = "sit";
    }
}
