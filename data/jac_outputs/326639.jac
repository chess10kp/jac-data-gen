def findPoisonedDuration(timeSeries: list[int], duration: int) -> int {
    n = len(timeSeries);
    if n == 0 {
        return 0;
    }
    head = 0;
    total_time = 0;
    for i in range(1, n) {
        d = timeSeries[i] - timeSeries[i - 1];
        if d > duration {
            total_time += timeSeries[i - 1] - timeSeries[head] + duration;
            head = i;
        }
    }
    total_time += timeSeries[n - 1] - timeSeries[head] + duration;
    return total_time;
}