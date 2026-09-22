"""Dynamic programing"""
def longest_palindrom_ver1(strs: str) -> str {
    if len(strs) < 2 or strs == strs[::-1] {
        return strs;
    }
    palins = [];
    for num in range(1, len(strs)) {
        for i in range(len(strs) - num) {
            if strs[i:(i + num + 1)][::-1] == strs[i:(i + num + 1)] {
                palins.append(strs[i:(i + num + 1)]);
                break;
            }
        }
    }
    palins.sort(key=len);
    return palins[-1];
}