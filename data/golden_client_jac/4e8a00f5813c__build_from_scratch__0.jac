can run with Root entry {
    visit [root-->[?:Day, date == today]] else {
        fresh_day = root +>: OnDay() :+> Day(date=today);
        visit fresh_day;
    }
}
