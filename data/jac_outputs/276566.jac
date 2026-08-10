"""Get the lists of debuff modifiers for a specific debuff type
    """
def getDebuff(state: Any, debuffType: Any) -> object {
    return [
        b['props'][debuffType]
        for b in state['enemy']['debuff']
        if (debuffType in b['props'])
    ];
}