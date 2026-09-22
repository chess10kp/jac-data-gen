"""Return the itemCode from itemID."""
def mappingIndexItemToName(index: int) -> str {
    match index {
        case 0:
            return 'R11';
        case 1:
            return 'R12';
        case 2:
            return 'R13';
        case 3:
            return 'R14';
        case 4:
            return 'R21';
        case 5:
            return 'R22';
        case 6:
            return 'R23';
        case 7:
            return 'R31';
        case 8:
            return 'R32';
        case 9:
            return 'R41';
    }
}