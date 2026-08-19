def linked_list_to_array(head: Any) -> object {
    array = [];
    curr = head;
    while curr {
        array.append(curr.val);
        curr = curr.next;
    }
    array.sort(reverse=True);
    return array;
}



with entry {
    print(linked_list_to_array(0));
}
