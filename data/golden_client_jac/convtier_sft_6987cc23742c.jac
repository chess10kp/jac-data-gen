node Hub {}
node Sensor { has reading: int; }
node Camera { has fps: int; }

walker HotScan {
    has low: int;
    has count: int = 0;
    can start with Hub entry { visit [-->][?:Sensor]; }
    can check with Sensor entry { if here.reading >= self.low { self.count += 1; } }
}

def count_hot_sensors(spec: dict) -> int {
    h = Hub();
    for d in list(spec["devices"]) {
        if d["kind"] == "sensor" { h ++> Sensor(reading=int(d["reading"])); }
        else { h ++> Camera(fps=int(d["fps"])); }
    }
    return (h spawn HotScan(low=int(spec["min"]))).count;
}

with entry {
    print(count_hot_sensors({'devices': [{'kind': 'sensor', 'reading': 7}, {'kind': 'camera', 'fps': 30}, {'kind': 'sensor', 'reading': 2}], 'min': 5}));
}
