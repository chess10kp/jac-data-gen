#!/usr/bin/env python3
# One-pass density/codespace probe: collect records at target coverage>=90
# offsets, then time py2jac + jac test for each. Fast(<10s,rc0)=native region.
import sys, time, tempfile, pathlib, subprocess, json
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))
import step4_full_loop as S
from datasets import load_dataset

TARGETS=[15000,19000,21000,23000,25000,27000,30000,35000,40000,50000,60000]
OUT=Path = pathlib.Path("data/chunk_probe.jsonl")
def emit(d):
    with open("data/chunk_probe.jsonl","a") as f: f.write(json.dumps(d)+"\n")
    print(json.dumps(d), flush=True)

# clean slate
open("data/chunk_probe.jsonl","w").close()

targets=set(TARGETS); got={}
ds=load_dataset(S.DATASET,split="train")
seen=0
for rec in ds:
    cov=rec.get("coverage")
    if cov is None or cov<90: continue
    seen+=1
    if seen in targets: got[seen]=rec
    if len(got)==len(targets): break
emit({"event":"collected","n":len(got)})

def run(cmd, t, to=60):
    try:
        r=subprocess.run(cmd,capture_output=True,text=True,cwd=t,timeout=to,
                         env={**__import__("os").environ,"TMPDIR":str(t)})
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return 124,"","TIMEOUT"

for off in sorted(got):
    rec=got[off]
    py_src=S.normalize_python(rec["content"].rstrip()+"\n\n"+"\n".join(rec["tests"])+"\n")
    with tempfile.TemporaryDirectory() as t:
        t=pathlib.Path(t); (t/f"{rec['id']}.py").write_text(py_src)
        rc,o,e=run(["jac","tool","py2jac",str(t/f"{rec['id']}.py")],t)
        if rc!=0:
            emit({"offset":off,"id":rec["id"],"result":"py2jac_fail","rc":rc}); continue
        g=t/f"{rec['id']}.jac"; g.write_text(S.with_entry_to_tests(o))
        t0=time.perf_counter()
        rc2,o2,e2=run(["jac","test",str(g)],t,to=45)
        dt=time.perf_counter()-t0
        emit({"offset":off,"id":rec["id"],"result":"test_rc","rc":rc2,"sec":round(dt),"tail":(e2 or o2)[-120:]})
