"""
    Searches for aliased pins in the timing model.
    The check is done using data from pin_aliases dictionary.
    The dictionary has an entry for each aliased pin.
    Each entry has two fields:

    * names : a list of all the possible aliases
    * is_property_related: a flag saying if the alias is in fact
            pin name combined with BEL property (e.g. Q[LH] pins
            in FF - in this case the pin name is Q [original name],
            but is named Q[LH] in the timing model. The suffix
            determines polarity of the FF's set/reset input).

    If is_property_related is set the function returns the original
    pin name, aliased name is returned otherwise.

    Parameters
    ----------
        pin: str
            Pin name to look for
        model: str
            Timing model
        pin_aliases: dict
            A dict of list of aliases for given bel/site

    Returns
    -------
        bool, str

        The first bool value is set to true if pin is found
        in the timing model, false otherwise.

        The second returned value is found pin name. If pin
        is not found None is returned

    >>> find_aliased_pin("a", "a_b_some_test_string", None)
    (False, None)

    >>> find_aliased_pin("d", "din_dout_setup", {"D": {"names" : ["din"], "is_property_related" : False}})
    (True, 'din')

    >>> find_aliased_pin("d", "din_dout_setup", {"D": {"names" : ["din"], "is_property_related" : True}})
    (True, 'd')

    >>> find_aliased_pin("d", "din_dout_setup", {"D": {"names" : ["notdin"], "is_property_related" : True}})
    (False, None)
    """
def find_aliased_pin(pin: Any, model: Any, pin_aliases: Any) -> object {
    if ((pin_aliases is not None) and (pin.upper() in pin_aliases)) {
        for alias in pin_aliases[pin.upper()]['names'] {
            single_word_alias = len(alias.split('_')) == 1;
            pin_alias = alias.lower();
            if single_word_alias {
                model_to_check = model.split('_');
            } else {
                model_to_check = model;
            }
            if (pin_alias in model_to_check) {
                if pin_aliases[pin.upper()]['is_property_related'] {
                    return (True, pin.lower());
                } else {
                    return (True, pin_alias);
                }
            }
        }
    }
    return (False, None);
}