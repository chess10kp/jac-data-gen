def removeDuplicates(head: Any) -> object {
    if (not head or not head.next) {
        return head;
    }
    head.next = removeDuplicatesHelper(head.next, head.data);
    return head;
}



with entry {
    print(removeDuplicates(0));
}
