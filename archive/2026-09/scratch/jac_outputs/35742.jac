""" split Sun May 10 18:23:32 +0000 2015 into NameOfDay Month Day Hour TimeZone Year"""
def splitDateTime(string: str) -> list[str] {
    return string.split(" ");
}