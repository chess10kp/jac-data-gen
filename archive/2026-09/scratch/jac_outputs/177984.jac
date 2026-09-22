"""
    At the first step, we should calculate the adjoint source for all the events.
    """
def calculate_adjoint_source_raw(
    py: Any,
    nproc: Any,
    misfit_windows_directory: Any,
    stations_path: Any,
    raw_sync_directory: Any,
    sync_directory: Any,
    data_directory: Any,
    output_directory: Any,
    body_band: Any,
    surface_band: Any
) -> object {
    script = f"ibrun -n {nproc} {py} -m seisflow.scripts.source_inversion.mpi_calculate_adjoint_source_zerolagcc_single_event --misfit_windows_directory {misfit_windows_directory} --stations_path {stations_path} --raw_sync_directory {raw_sync_directory} --sync_directory {sync_directory} --data_directory {data_directory} --output_directory {output_directory} --body_band {body_band} --surface_band {surface_band}; \n";
    return script;
}