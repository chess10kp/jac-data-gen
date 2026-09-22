"""Reclassify the museums using Iain's classification."""
def classify_type(`type: str) -> str {
    `type = `type[:5].upper();
    match `type {
        case 'AGRIC':
            classifed_type = 'Local';
        case 'AMUSE':
            classifed_type = 'Other';
        case 'ARCHA':
            classifed_type = 'Historic';
        case 'ART':
            classifed_type = 'Arts';
        case 'AUTOM':
            classifed_type = 'Transport';
        case 'AVIAT':
            classifed_type = 'Transport';
        case 'BIOGR':
            classifed_type = 'Local';
        case 'ENVIR':
            classifed_type = 'Local';
        case 'FASHI':
            classifed_type = 'Arts';
        case 'HISTO':
            classifed_type = 'Historic';
        case 'INDUS':
            classifed_type = 'Industrial';
        case 'LAW E':
            classifed_type = 'Local';
        case 'LIVIN':
            classifed_type = 'Local';
        case 'LOCAL':
            classifed_type = 'Local';
        case 'MARIT':
            classifed_type = 'Transport';
        case 'MEDIA':
            classifed_type = 'Arts';
        case 'MEDIC':
            classifed_type = 'Other';
        case 'MILIT':
            classifed_type = 'Other';
        case 'MILL':
            classifed_type = 'Industrial';
        case 'MININ':
            classifed_type = 'Industrial';
        case 'MULTI':
            classifed_type = 'Multiple';
        case 'MUSIC':
            classifed_type = 'Other';
        case 'NATUR':
            classifed_type = 'Other';
        case 'OPEN ':
            classifed_type = 'Other';
        case 'PHILA':
            classifed_type = 'Other';
        case 'PHOTO':
            classifed_type = 'Arts';
        case 'PRISO':
            classifed_type = 'Local';
        case 'RAILW':
            classifed_type = 'Transport';
        case 'RELIG':
            classifed_type = 'Other';
        case 'RURAL':
            classifed_type = 'Other';
        case 'SCIEN':
            classifed_type = 'Other';
        case 'SPORT':
            classifed_type = 'Other';
        case 'TECHN':
            classifed_type = 'Other';
        case 'TEXTI':
            classifed_type = 'Arts';
        case 'TOY':
            classifed_type = 'Arts';
        case 'TRANS':
            classifed_type = 'Transport';
        case _:
            classifed_type = 'Other';
    }
    return classifed_type;
}