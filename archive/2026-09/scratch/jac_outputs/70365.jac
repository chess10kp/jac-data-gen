"""Calculates difference between two times given in input and returns difference."""
def calculateDifferenceBetweenTimePeriod(time1: str, time2: str) -> str {
    l1 = time1.split(':');
    l2 = time2.split(':');
    sec1 = int(l1[2]);
    min1 = int(l1[1]);
    hr1 = int(l1[0]);
    sec2 = int(l2[2]);
    min2 = int(l2[1]);
    hr2 = int(l2[0]);
    sec = sec1 - sec2 if sec1 > sec2 else sec2 - sec1;
    min3 = min1 - min2 if min1 > min2 else min2 - min1;
    hr = hr1 - hr2 if hr1 > hr2 else hr2 - hr1;
    return str(hr) + ':' + str(min3) + ':' + str(sec);
}