"""function used to check if the input member id is valid"""
def member_id_validation(input_id: str) -> int {
    if len(input_id) != 4 {
        return 1;
    } elif input_id.isdigit() {
        return 0;
    } else {
        return 2;
    }
}