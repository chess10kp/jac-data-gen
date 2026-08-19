def check_time(hour: int) -> str {
    if hour < 12 {
        return "Good morning!";
    } elif hour < 17 {
        return "Good afternoon!";
    } else {
        return "Good evening!";
    }
}

with entry {
    # For loop over a list
    tasks = ["Buy groceries", "Team standup", "Go running"];
    for task in tasks {
        print(f"- {task}");
    }

    # Range-based loop
    for i in range(5) {
        print(i);  # 0, 1, 2, 3, 4
    }
}
