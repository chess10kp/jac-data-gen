def length() -> int {
    count = 1;
    cur = self.next;
    while cur { count += 1; cur = cur.next; }
    return count;
}
