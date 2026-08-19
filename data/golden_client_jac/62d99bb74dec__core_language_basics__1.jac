obj ValidationError(Exception) {
    has field: str;
    has message: str;
}

def validate(data: dict) -> None {
    if "name" not in data {
        raise ValidationError(field="name", message="Name is required");
    }
}
