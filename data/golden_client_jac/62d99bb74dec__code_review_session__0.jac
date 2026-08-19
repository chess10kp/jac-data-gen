obj ValidationError(Exception) {
    has field: str;
    has message: str;
    def postinit {
        super.__init__(self.message);
    }
}
def validate(data: dict) {
    if "name" not in data {
        raise ValidationError(field="name", message="Name is required");
    }
}
