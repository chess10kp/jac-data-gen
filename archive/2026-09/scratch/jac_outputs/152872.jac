"""Convert user-input filename for master into full name."""
def user_master_name(mdir: str, input_name: str) -> str {
    islash = input_name.find('/');
    if islash >= 0 {
        full_name = input_name;
    } else {
        full_name = mdir + '/' + input_name;
    }
    return full_name;
}