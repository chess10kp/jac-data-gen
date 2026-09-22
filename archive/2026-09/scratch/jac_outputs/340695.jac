"""Convert pH between temperatures.

    Parameters
    ----------
     pH : float
        pH as measured.
     original_temperature : float
        Measurement temperature, in degrees Fahrenheit.
     desired_temperature : float
        Temperature relative to which to express the pH.

    Returns
    -------
     pH : float
        The pH that would be measured at the desired temperature.

    Notes
    -----
     The pH measured by a probe will vary based on the temperature of
     the sample for two reasons. The first is that the probe itself
     works according to electrochemical principles that vary according
     to the temperature. This is specific to the probe and has nothing
     to do with what is being measured. Many probes are branded as
     having "Automatic Temperature Correction" or "ATC", and those
     probes correct for this first phenomenon automatically.

     The second reason for variation is due to the intrinsic pH
     dependency on the temperature of the sample. Basically, the same
     substance at different temperatures really does have different pH
     levels. The variation depends on the substance and thus cannot
     automatically be corrected for by the probe, since the probe
     would have to know the details of the substance. For beer, a
     rough linear relationship holds over a range of desirable
     temperatures.

     This function permits the brewer to measure the sample at any
     temperature (provided it is reasonably close to room temperature;
     to do otherwise risks damage to the probe), and convert the
     measurement to a reference temperature for assessment.

    """
def convert_pH_temp(
    pH: float, original_temperature: float, desired_temperature: float
) -> float {
    return pH - 0.003 * (desired_temperature - original_temperature);
}