edge Scheduled {
    has time: str;
    has priority: int = 1;
}

with entry {
    root +>: Scheduled(time="9:00am", priority=3) :+> Task(title="Morning run");

    # Query through typed edges
    urgent = [root->:Scheduled:priority>=3:->][?:Task];
}
