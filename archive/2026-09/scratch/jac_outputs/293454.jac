"""Assuming format like: { GetUserByEmail(email: "someemail") { ... } }"""
def get_email_value(operation_definition: str) -> str {
    text_after_email = operation_definition.split('email:')[1];
    unquoted_tokens = text_after_email.split('"');
    return unquoted_tokens[1];
}