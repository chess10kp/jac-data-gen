with entry {
        name = "Jac";
        nums = [1, 2, 3, 4, 5];
        info = {"language": name, "version": "0.10"};
        evens = [x for x in nums if x % 2 == 0];
        print(f"{name} evens: {evens}");
        print(f"Info: {info}");
    }
