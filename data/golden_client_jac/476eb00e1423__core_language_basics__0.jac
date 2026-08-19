with entry {
    age = 25;
    has_license = True;

    # AND - both must be true
    if age >= 16 and has_license {
        print("You can drive!");
    }

    # OR - at least one must be true
    if age < 18 or age > 65 {
        print("Discounted ticket price!");
    }

    # NOT - reverse the condition
    if not has_license {
        print("You need a license!");
    }
}
