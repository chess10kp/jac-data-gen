#!/usr/bin/env python3
# Validate: does `jac check` codespace predict fast-test-pass vs slow-test-fail?
# Writes results to data/native_probe.txt so output survives any pipe/kill.
import sys, tempfile, pathlib, subprocess, time, os
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))
import step4_full_loop as S
from datasets import load_dataset
OUT=open("data/native_probe.txt","w")
def log(*a): print(*a, flush=True); print(*a, file=OUT, flush=True)
ds=load_dataset(S.DATASET,split="train")
def get(offset):
    seen=0
    for rec in ds:
        cov=rec.get("coverage")
        if cov is None or cov<90: continue
        seen+=1
        if seen==offset: return rec
def probe(rec,label):
    if not rec: log(f"{label}: no-rec"); return
    py_src=S.normalize_python(rec["content"].rstrip()+"\n\n"+"\n".join(rec["tests"])+"\n")
    with tempfile.TemporaryDirectory() as t:
        t=pathlib.Path(t); (t/f"{rec['id']}.py").write_text(py_src)
        env={**os.environ,"TMPDIR":str(t)}
        r=subprocess.run(["jac","tool","py2jac",str(t/f"{rec['id']}.py")],capture_output=True,text=True,env=env)
        if r.returncode!=0: log(f"{label} id={rec['id']}: py2jac_fail"); return
        floor=r.stdout
        chk=t/f"{rec['id']}.jac"; chk.write_text(floor)
        t0=time.perf_counter()
        r2=subprocess.run(["jac","check",str(chk)],capture_output=True,text=True,env=env,timeout=40)
        dchk=time.perf_counter()-t0
        blob=(r2.stderr+" "+r2.stdout)
        cs="server" if "server" in blob.lower() else ("native" if "native" in blob.lower() else "?")
        log(f"{label} id={rec['id']}: check rc={r2.returncode} {dchk:.0f}s codespace~={cs}")
        g=t/f"{rec['id']}_t.jac"; g.write_text(S.with_entry_to_tests(floor))
        t1=time.perf_counter()
        try:
            r3=subprocess.run(["jac","test",str(g)],capture_output=True,text=True,env=env,timeout=60)
            log(f"   test rc={r3.returncode} {time.perf_counter()-t1:.0f}s")
        except subprocess.TimeoutExpired:
            log(f"   test TIMEOUT >60s")
log("=== native-census validation ===")
probe(get(1),"off0_1st")    # passed manually before
probe(get(3),"off0_3rd")
probe(get(9001),"off9000")  # known-good region
OUT.close()
