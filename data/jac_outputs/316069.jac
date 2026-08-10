"""Convert axisheader dictionary to list."""
def dic2axisheader(dic: dict[str, int | float]) -> list[int | float] {
    return [
        dic["nucleus"],
        dic["spectral_shift"],
        dic["npoints"],
        dic["size"],
        dic["bsize"],
        dic["spectrometer_freq"],
        dic["spectral_width"],
        dic["xmtr_freq"],
        dic["zero_order"],
        dic["first_order"],
        dic["first_pt_scale"],
        dic["extended"],
    ];
}