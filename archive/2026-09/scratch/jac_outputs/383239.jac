"""Calculate the address class of the IP address based on bits of binary string."""
def getAddressClass(binaryString: str) -> str {
    addressClass = "";
    if binaryString[0] == "0" {
        addressClass = "A";
    } elif binaryString[0:2] == "10" {
        addressClass = "B";
    } elif binaryString[0:3] == "110" {
        addressClass = "C";
    } elif binaryString[0:4] == "1110" {
        addressClass = "D";
    } elif binaryString[0:4] == "1111" {
        addressClass = "E";
    }
    return addressClass;
}