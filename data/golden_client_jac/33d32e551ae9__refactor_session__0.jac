def check_time(hour: int) -> str {
    if hour < 12 {
        return "Good morning!";
    } elif hour < 17 {
        return "Good afternoon!";
    } else {
        return "Good evening!";
    }
}

def show_tasks(tasks: list) -> None {
    for task in tasks {
        print(f"- {task}");
    }
}

def count_down(start: int) -> None {
    count = start;
    while count > 0 {
        print(f"Countdown: {count}");
        count -= 1;
    }
}

with entry {
    show_tasks(["Buy groceries", "Team standup", "Go running"]);
    for i in range(5) {
        print(i);
    }
    count_down(3);
    hour = 10;
    mood = "energized" if hour < 12 else "tired";
    print(mood);
}
