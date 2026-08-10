"""Returns 'label'=value[UOM];[warn];[crit];[min];[max] """
def get_perfdata(
    label: str,
    value: int | float | str,
    uom: str | None,
    warn: int | float | str | None,
    crit: int | float | str | None,
    _min: int | float | str | None,
    _max: int | float | str | None
) -> str {
    msg = "'{}'={}".format(label, value);
    if uom is not None {
        msg += uom;
    }
    msg += ';';
    if warn is not None {
        msg += str(warn);
    }
    msg += ';';
    if crit is not None {
        msg += str(crit);
    }
    msg += ';';
    if _min is not None {
        msg += str(_min);
    }
    msg += ';';
    if _max is not None {
        msg += str(_max);
    }
    msg += ' ';
    return msg;
}