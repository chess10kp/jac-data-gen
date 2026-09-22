"""
Turns the malware_keywords to lower case and return
the keywords dictionary so it is case insensitive

args
malware_keywords -- the keywords of malwares to the number
            of times they appear
"""
def prepare_malware_keywords(malware_keywords: dict[str, int]) -> dict[str, int] {
    return {k.lower(): v for (k, v) in malware_keywords.items()};
}