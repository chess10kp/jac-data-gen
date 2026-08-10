"""
Given an array of time intervals (start, end) for classroom lectures (possibly overlapping),
find the minimum number of rooms required.
"""
def coding_problem_21(times: list[tuple[int, int]]) -> int {
    start_times = [(t[0], 1) for t in times];
    end_times = [(t[1], -1) for t in times];
    room_allocation = [
        t[1] for t in sorted(
            start_times + end_times,
            key=lambda (t: tuple[int, int]) { t[0]; }
        )
    ];
    (rooms, max_rooms) = (0, 0);
    for event in room_allocation {
        rooms += event;
        max_rooms = max(max_rooms, rooms);
    }
    assert rooms == 0;
    return max_rooms;
}