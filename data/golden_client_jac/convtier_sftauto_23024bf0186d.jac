def calculate_photon_energy(wavelength: Any) -> object {
    plancks_constant = 6.62607004e-34;
    speed_of_light = 300000000.0;
    frequency = speed_of_light / wavelength;
    energy = plancks_constant * frequency;
    return energy;
}



with entry {
    print(calculate_photon_energy(5));
    print(calculate_photon_energy(10));
    print(calculate_photon_energy(2));
}
