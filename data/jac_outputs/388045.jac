"""
aux data for sos kernel
"""
def make_metadata_sos() -> dict[str, object] {
    return {
        "celltoolbar": "Create Assignment",
        "kernelspec": {"display_name": "SoS", "language": "sos", "name": "sos"},
        "language_info": {
            "codemirror_mode": "sos",
            "file_extension": ".sos",
            "mimetype": "text/x-sos",
            "name": "sos",
            "nbconvert_exporter": "sos_notebook.converter.SoS_Exporter",
            "pygments_lexer": "sos"
        },
        "sos": {
            "kernels": [
                ["Bash", "bash", "bash", "", "shell"],
                ["C", "c_kernel", "c", "", ""],
                ["OCaml default", "ocaml-jupyter", "OCaml", "", "text/x-ocaml"],
                [
                    "Python 3 (ipykernel)",
                    "python3",
                    "python3",
                    "",
                    {"name": "ipython", "version": 3}
                ]
            ],
            "panel": {"displayed": True, "height": 0},
            "version": "0.21.21"
        }
    };
}