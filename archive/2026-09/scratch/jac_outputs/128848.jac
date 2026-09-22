"""
Check if source snippet can be run in the REPL thread, as opposed to GUI mainloop
(to prevent unnecessary hanging of mainloop).
"""
def run_in_frontend(src: str) -> bool {
    return src.startswith('_ip.system(') and not '\n' in src;
}