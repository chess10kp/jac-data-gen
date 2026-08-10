"""Easy way to create test data for hash to test."""
def hash_to_test() -> tuple[str, str, str, str] {
    text_test = 'hello';
    text_format = 'utf-8';
    hash_test = '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
    element_id = 'id_text';
    return (text_test, text_format, hash_test, element_id);
}