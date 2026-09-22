"""Set vars for the thermodriver run using the run_jobs_lst."""
def set_thermodriver(run_jobs_lst: list[str]) -> tuple[bool, bool, bool] {
    write_messpf = False;
    run_messpf = False;
    run_nasa = False;
    if 'thermochem' in run_jobs_lst {
        write_messpf = True;
        run_messpf = True;
        run_nasa = True;
    } else {
        if 'write_messpf' in run_jobs_lst {
            write_messpf = True;
        }
        if 'run_messpf' in run_jobs_lst {
            run_messpf = True;
        }
        if 'run_nasa' in run_jobs_lst {
            run_nasa = True;
        }
    }
    return (write_messpf, run_messpf, run_nasa);
}