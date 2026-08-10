"""
    :param name: sensor name
    :param lane_number: lane number of this sensor
    :param if_alias: interface alias
    :return: description string about sensor
    """
def get_transceiver_sensor_description(
    name: str, lane_number: int, if_alias: str
) -> str {
    port_name = if_alias if lane_number == 0 else "{}/{}".format(if_alias, lane_number);
    return "DOM {} Sensor for {}".format(name, port_name);
}