"""Transform coordinates into a string for API"""
def coord_to_string(coordinates: tuple | dict | list | str) -> str | None {
    string: str | None = None;
    if type(coordinates) == tuple {
        string = ','.join(list(map(str, coordinates as tuple)));
    } elif type(coordinates) == dict {
        string = ','.join(list(map(str, (coordinates as dict).values())));
    } elif type(coordinates) == list and len(coordinates) == 2 {
        string = ','.join(list(map(str, coordinates as list)));
    } elif type(coordinates) == str {
        string = coordinates as str;
    } else {
        print('invalid coordinate type');
        string = None;
    }
    return string;
}