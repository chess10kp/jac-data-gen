""" This currently ONLY works when registrationImageTypes has
        length of exactly 1.  When the new multi-variate registration
        is introduced, it will be expanded.
    """
def GetMovingImages(
    ListOfImagesDictionaries: list[dict[str, object]],
    registrationImageTypes: list[str],
    interpolationMapping: dict[str, object]
) -> list[object] | tuple[list[object], object] {
    if len(registrationImageTypes) != 1 {
        print("ERROR:  Multivariate imageing not supported yet!");
        return [];
    }
    moving_images = [
        mdict[registrationImageTypes[0]] for mdict in ListOfImagesDictionaries
    ];
    moving_interpolation_type = interpolationMapping[registrationImageTypes[0]];
    return (moving_images, moving_interpolation_type);
}