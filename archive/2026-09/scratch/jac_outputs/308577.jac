def unpack_plot_settings(panel_dict: dict[str, dict[str, float]], `entry: str) -> list[float] {
    return [
        panel_dict[key][`entry]
        for key in ['panel_' + str(i + 1) for i in range(len(panel_dict))]
    ];
}