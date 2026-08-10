"""Changes the format from am/pm to 24h system."""
def changeFrom12To24(aString: str) -> str {
    return {
        "1": "13",
        "2": "14",
        "3": "15",
        "4": "16",
        "5": "17",
        "6": "18",
        "7": "19",
        "8": "20",
        "9": "21",
        "10": "22",
        "11": "23",
    }.get(aString, aString);
}