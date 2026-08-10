"""Function to get the timing for the PMU recording."""
def getPMUtiming(lines: list[str]) -> tuple[list[int], list[int]] {
    mpcu_time = [0, 0];
    mdh_time = [0, 0];
    for line in lines {
        if 'MPCUTime' in line {
            parts = line.split();
            if 'LogStart' in line {
                mpcu_time[0] = int(parts[1]);
            } elif 'LogStop' in line {
                mpcu_time[1] = int(parts[1]);
            }
        }
        if 'MDHTime' in line {
            parts = line.split();
            if 'LogStart' in line {
                mdh_time[0] = int(parts[1]);
            } elif 'LogStop' in line {
                mdh_time[1] = int(parts[1]);
            }
        }
    }
    return (mpcu_time, mdh_time);
}