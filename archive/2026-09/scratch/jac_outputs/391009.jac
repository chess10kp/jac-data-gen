"""
    Utility function to construct a list of command-line arguments in the form that is stored
    in sys.argv. This can then be fed to the main function and used to run CoverView.
    """
def make_command_line_arguments(
    bam_file_name: str,
    bed_file_name: str | None,
    config_file_name: str | None,
    transcript_file_name: str | None,
    gui_output_file_name: str | None
) -> list[str] {
    arguments_list = ["-i", bam_file_name];
    if bed_file_name is not None {
        arguments_list.extend(["-b", bed_file_name]);
    }
    if config_file_name is not None {
        arguments_list.extend(["-c", config_file_name]);
    }
    if transcript_file_name is not None {
        arguments_list.extend(["-t", transcript_file_name]);
    }
    if gui_output_file_name is not None {
        arguments_list.extend(["--gui_json_output_file", gui_output_file_name]);
    }
    return arguments_list;
}