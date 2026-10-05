node Location {
    has name: str;
    has risk_level: int = 0;
}

walker DisasterMonitor {

    has fire_strength: int = 2;

    can enter with Location entry {

        here.risk_level = here.risk_level + self.fire_strength;

        report here.name;
        report here.risk_level;
    }
}