"""Weather station sweep: reporting readings back mid-traversal.

Each station reports its temperature as the walker passes through,
without ending the trip. Reports accumulate in order, so the main
block can read them back as a time series.
"""

node WeatherStation {
    has location: str = "";
    has temperature_c: float = 0.0;
}

walker Sweep {
    has day: str = "";

    can start with Root entry {
        print(f"Starting weather sweep for {self.day}");
        visit [-->];
    }

    can read with WeatherStation entry {
        report here.temperature_c;
        visit [-->];
    }
}

with entry {
    root ++> WeatherStation(location="Coast", temperature_c=18.5)
        ++> WeatherStation(location="Valley", temperature_c=24.0)
        ++> WeatherStation(location="Summit", temperature_c=9.5);

    result = root spawn Sweep(day="Tuesday");
    print(f"Readings on {result.reports}");
    lo = min(result.reports);
    hi = max(result.reports);
    print(f"Range across stations: {lo} to {hi} C");
}
