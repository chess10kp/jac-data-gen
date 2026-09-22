"""Exchange the smallest prefixes of first and second that have equal sum."""
def trade(first: list[int], second: list[int]) -> str {
    m = 1;
    n = 1;
    if not first or not second {
        return 'No deal!';
    }
    suma = first[0];
    sumb = second[0];
    while suma != sumb and m < len(first) and n < len(second) {
        if suma < sumb {
            suma = suma + first[m];
            m = m + 1;
        } else {
            sumb = sumb + second[n];
            n = n + 1;
        }
    }
    if suma == sumb {
        (first[:m], second[:n]) = (second[:n], first[:m]);
        return 'Deal!';
    }
    return 'No deal!';
}