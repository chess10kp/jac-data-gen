"""
       TOPOLOGY DEFINITION

       Some attributes of fog entities (nodes) are approximate
       """
def create_json_topology() -> object {
    topology_json = {};
    topology_json["entity"] = [];
    topology_json["link"] = [];
    cloud_dev = {
        "id": 0,
        "model": "cloud",
        "mytag": "cloud",
        "IPT": (5000 * (10 ** 6)),
        "RAM": 40000,
        "COST": 3,
        "WATT": 20.0
    };
    sensor_dev = {
        "id": 1,
        "model": "sensor-device",
        "IPT": (100 * (10 ** 6)),
        "RAM": 4000,
        "COST": 3,
        "WATT": 40.0
    };
    actuator_dev = {
        "id": 2,
        "model": "actuator-device",
        "IPT": (100 * (10 ** 6)),
        "RAM": 4000,
        "COST": 3,
        "WATT": 40.0
    };
    link1 = {"s": 0, "d": 1, "BW": 1, "PR": 10};
    link2 = {"s": 0, "d": 2, "BW": 1, "PR": 1};
    topology_json["entity"].append(cloud_dev);
    topology_json["entity"].append(sensor_dev);
    topology_json["entity"].append(actuator_dev);
    topology_json["link"].append(link1);
    topology_json["link"].append(link2);
    return topology_json;
}