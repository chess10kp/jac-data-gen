def check_person(age: int, has_license: bool) -> None {
    if age >= 16 and has_license {
        print("You can drive!");
    }
    if age < 18 or age > 65 {
        print("Discounted ticket price!");
    }
    if not has_license {
        print("You need a license!");
    }
}

with entry {
    check_person(25, True);
}
