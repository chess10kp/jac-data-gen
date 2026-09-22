"""Create mch-filename for icon ctrl run for given leadtime.

    Args:
        lt (int): leadtime

    Returns:
        str: filename of icon output simulation in netcdf, following mch-convention

    """
def lfff_name(lt: Any) -> object {
    hour = int(lt) % 24;
    day = (int(lt) - hour) // 24;
    remaining_s = round(((lt - int(lt)) * 3600));
    sec = int((remaining_s % 60));
    mm = int(((remaining_s - sec) / 60));
    return f"lfff{day:02}{hour:02}{mm:02}{sec:02}.nc";
}