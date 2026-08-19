obj Dog {
    has secret: str = "",
        trick: str = "";

    def rename() {
        self.secret = "oops";
    }

    def train() {
        self.trick = "sit";
    }
}
