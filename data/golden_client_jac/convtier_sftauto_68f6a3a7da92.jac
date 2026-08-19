def convertToDoublyLinkedList(head: Any) -> object {
    if (head is None) {
        return None;
    }
    current = head;
    prev = None;
    while current {
        current.prev = prev;
        prev = current;
        current = current.next;
    }
    return head;
}



with entry {
    print(convertToDoublyLinkedList(0));
    print(convertToDoublyLinkedList([]));
}
