def remove_duplicates(head: Any) -> object {
    current = head;
    while current {
        runner = current;
        while runner.next {
            if (runner.next.data == current.data) {
                runner.next = runner.next.next;
            } else {
                runner = runner.next;
            }
        }
        current = current.next;
    }
    return head;
}



with entry {
    print(remove_duplicates(0));
    print(remove_duplicates([]));
}
