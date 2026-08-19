with entry {
    ages = {"Alice": 25, "Bob": 30, "Charlie": 22};
    oldest_name = "";
    for name in ages {
        if ages[name] > ages[oldest_name] {
            oldest_name = name;
        }
    }
    print(oldest_name);
}
