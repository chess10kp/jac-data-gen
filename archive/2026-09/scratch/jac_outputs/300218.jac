"""

    :param queue: list - names in the queue.
    :param person_name: str - name you wish to count or track.
    :return:  int - the number of times the name appears in the queue.
    """
def how_many_namefellows(queue: list, person_name: str) -> int {
    cnt = 0;
    for name in queue {
        if (name == person_name) {
            cnt += 1;
        }
    }
    return cnt;
}