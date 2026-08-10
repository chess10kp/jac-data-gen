""" Construct the UNWISE specific URL to download UNWISE cutouts.

    :param ra: float
        Right ascension of target
    :param dec: float
        Declination of target
    :param npix: float
        Cutout image size in pixels
    :param band: str
        Passband of the image
    :param data_release: str
        String specifying the unwise data release. Possible values are: neo1,
        neo2, neo3, neo4, neo5. neo6, allwise
    :param verbosity: int
        Verbosity > 0 will print verbose statements during the execution
    :return: str
        Returns the url to the DES DR1 image cutout
    """
def get_unwise_image_url(
    ra: Any, dec: Any, npix: Any, band: Any, data_release: Any, filetype: Any = "image"
) -> object {
    if (npix >= 256) {
        npix = 256;
    }
    datatype = {
        "image": "&file_img_m=on",
        "std": "&file_std_m=on",
        "invvar": "&file_invvar_m=on"
    };
    file_type = datatype[filetype];
    base = "http://unwise.me/cutout_fits?version={}&".format(data_release);
    ra = "ra={:0}&".format(ra);
    dec = "dec={:0}&".format(dec);
    size = "size={:0}&".format(npix);
    if ((data_release in ['neo4', 'neo5', 'neo6']) and (band in ['3', '4'])) {
        print(
            '[ERROR] Download of band w{} in unwise-{} not ' 'available'.format(
                band, data_release
            )
        );
        return None;
    } else {
        band = "bands={0:s}".format(band);
        url = base + ra + dec + size + band + file_type;
        return url;
    }
}