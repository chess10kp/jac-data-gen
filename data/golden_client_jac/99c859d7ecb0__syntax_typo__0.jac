with entry {
    ages = {"Alice": 25, "Bob": 30, "Charlie": 22};

    oldest_name = "";
    oldest_age = 0;

    for name in ages {
        if ages[name] > oldest_age {
            oldest_age = ages[name];
            oldest_name = name;
        }
    }

    print(f"{oldest_name} is the oldest at {oldest_age}");
}
