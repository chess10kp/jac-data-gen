"""Convert dg_classification to demisto sensitivity."""
def convert_to_demisto_sensitivity(dg_classification: str) -> str {
    demisto_sensitivity = 'none';
    if dg_classification {
        match dg_classification[-3:] {
            case 'ext':
                demisto_sensitivity = 'Critical';
            case 'IGH':
                demisto_sensitivity = 'High';
            case 'MED':
                demisto_sensitivity = 'Medium';
            case 'LOW':
                demisto_sensitivity = 'Low';
        }
    }
    return demisto_sensitivity;
}