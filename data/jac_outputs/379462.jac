"""intervals: list of tuples representing context windows"""
def merge(intervals: list[list[int]]) -> list[list[int]] {
    ans = [];
    i = 1;
    intervals.sort();
    tempans = intervals[0];
    while i < len(intervals) {
        if tempans[0] <= intervals[i][1] and tempans[1] >= intervals[i][0] {
            tempans = [
                min(tempans[0], intervals[i][0]),
                max(tempans[1], intervals[i][1])
            ];
            i += 1;
        } else {
            ans.append(tempans);
            tempans = intervals[i];
            i += 1;
        }
    }
    ans.append(tempans);
    return ans;
}