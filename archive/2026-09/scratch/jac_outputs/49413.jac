"""Find the crime parameters in the .csv file and converts them from strings (str) to integers (int) for later comparison"""
def crimeValue(crimeStr: Any) -> object {
    if (crimeStr == "low") {
        crimeInt = 1;
    } elif (crimeStr == "average") {
        crimeInt = 2;
    } elif (crimeStr == "high") {
        crimeInt = 3;
    } else {
        crimeInt = 0;
    }
    return crimeInt;
}