def get_linked_list_length(head: Any) -> object {
    count = 0;
    current = head;
    while current {
        count += 1;
        current = current.next;
    }
    return count;
}



with entry {
    print(get_linked_list_length(0));
}
