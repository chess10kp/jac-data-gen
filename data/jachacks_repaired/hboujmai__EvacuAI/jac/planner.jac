node Location {
    has name: str;
    has risk: int = 0;
}

walker EvacuationPlanner {

    can enter with Location entry {

        if here.risk >= 7 {
            report here.name + " → BLOCKED";
        }

        elif here.risk >= 4 {
            report here.name + " → WARNING";
        }

        else {
            report here.name + " → SAFE";
        }
    }
}