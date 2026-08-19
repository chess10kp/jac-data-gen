def minimize_rope_cut(total_length: Any) -> object {
    if (total_length <= 10) {
        return total_length;
    } else {
        segments = total_length // 10;
        remainder = total_length % 10;
        if (remainder == 0) {
            return (segments * 10);
        } else {
            return ((segments * 10) + remainder);
        }
    }
}



with entry {
    print(minimize_rope_cut(5));
    print(minimize_rope_cut(10));
    print(minimize_rope_cut(2));
}
