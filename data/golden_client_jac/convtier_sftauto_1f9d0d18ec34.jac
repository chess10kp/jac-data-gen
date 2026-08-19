def compute_product(arr: Any) -> object {
    product = 1;
    seen = `set();
    for num in arr {
        if ((num == 2) or (num == 3) or (num == 5)) {
            continue;
        }
        if (((num % 3) == 0) and ((num % 5) == 0)) {
            if (num not in seen) {
                product *= num;
                seen.add(num);
            }
        }
    }
    return round(product);
}



with entry {
    print(compute_product([81]));
}
