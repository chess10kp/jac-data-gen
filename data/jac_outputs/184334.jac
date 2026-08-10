"""extract end coordinates from input text
    :input data (str): plain text read from txt file
    :returns end_coordinates (list of list of tuples)"""
def get_lines_coordinates(input_data: Any) -> object {
    input_lines = input_data.split("\n");
    end_coordinates = [];
    for il in input_lines {
        if (il != "") {
            res = il.strip().split(" -> ");
            end_coordinates.append(
                [
                    (int(res[0].split(",")[0]), int(res[0].split(",")[1])),
                    (int(res[1].split(",")[0]), int(res[1].split(",")[1]))
                ]
            );
        }
    }
    return end_coordinates;
}