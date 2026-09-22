# Function eval grading: 08 vs base under jac 0.36.1

Everything needed is in this folder. The only extra download is the jac 0.36.1
binary (about 200 MB), which `run.sh` fetches and checksums for you.

## What this is

Two models were asked to write Jac for jac-data-gen's `evals/function/v1` test split:
1000 tasks, 500 completion (finish a partly written function) and 500 translation
(Python to Jac). Each task has hidden `test` blocks. A task passes when the code
compiles (`jac check`), every hidden test passes (`jac test`), and the code keeps
to the task's feature contract (no Python syntax, and so on).

The original grade used jaclang 0.16.1. This run re-grades everything under jac
0.36.1, which is the toolchain the eval targets.

## Contents

| path | what |
|---|---|
| `run.sh` | does the whole job: downloads jac 0.36.1, grades both models, prints a summary |
| `preds/08_samples.jsonl` | model outputs, Qwen3-Coder-30B-A3B (MLX 4-bit) + experiment 08 LoRA adapter |
| `preds/base_samples.jsonl` | model outputs, same base model with no adapter |
| `eval/eval_jac.py` | the grader, copied unchanged from github.com/chess10kp/jac-data-gen (commit `5222202a`), `scripts/eval/eval_jac.py` |
| `eval/test.jsonl` | the task file with the hidden tests, from that repo's `evals/function/v1/private/test.jsonl` |
| `provenance.json` | settings from the original run |

## Requirements

- macOS or Linux, arm64 or x86_64
- `python3` 3.8 or newer (the grader only uses the standard library)
- `curl`
- about 1 GB of free disk, plus temporary files while the grader runs

## Steps

1. Unpack and go into the folder:

   ```sh
   tar xzf fn_eval_preds.tar.gz && cd fn_eval_preds
   ```

2. Check the setup on a few tasks (about a minute, plus the download on the first run):

   ```sh
   SMOKE=6 ./run.sh
   ```

   Each model should print a line with `'samples': 6` and `'complete': True`.

3. Start the full run so it keeps going after you log out:

   ```sh
   nohup ./run.sh > run.log 2>&1 &
   tail -f run.log        # Ctrl-C stops watching; the run keeps going
   ```

   Options, which work with steps 2 and 3:
   - `WORKERS=8` sets the number of grader threads. The default is 4. Each thread
     starts 2 pytest workers, so 4 threads use about 8 cores.
   - `MODELS=08` grades one model only.
   - `JAC=/path/to/jac` uses a jac 0.36.1 binary you already have.

## How long it takes

On an M-series Mac with 4 threads, the original 0.36.1 check graded 50 of these
tasks in about 2 minutes. Scaled up, that's roughly 40 to 60 minutes per model,
so about 1 to 2 hours for both. That's an estimate: task sizes vary, and the
grader gives each stage up to 900 s before it records a timeout.

To check progress while it runs, look at `out/08/grade.log` or `out/base/grade.log`.
The grader writes `results.jsonl` and `summary.json` only once a model is done.

## Send back

Zip up the whole `out/` folder plus `run.log`:

```sh
tar czf fn_eval_results.tar.gz out run.log
```

`out/<model>/summary.json` has the overall rates, `out/<model>/results.jsonl` has
one row per task, and `out/<model>/grade.log` has the grader's console output.

## If something goes wrong

- **`grader exit 2`**: some tasks hit an infrastructure error, not a model error.
  The summary shows `'complete': False`. Re-run that model (for example
  `MODELS=base ./run.sh`) and send the log if it happens again.
- **Many `timeout` statuses in `status_counts`**: the machine is overloaded. Re-run
  with a lower `WORKERS`.
- **`sha256 mismatch`**: the download was corrupted. Delete `bin/` and run again.
- **macOS says the jac binary can't be opened**: run `xattr -d com.apple.quarantine bin/jac-0.36.1`.

## Numbers so far, under 0.16.1, for comparison

| model | pass@1 | compiles | completion | translation |
|---|---|---|---|---|
| 08 | 57.0% | 71.5% | 30.8% | 83.2% |
| base | 3.0% | 5.7% | 6.0% | 0.0% |

On the 50-task subset graded under 0.36.1, 08 scored 54.0% (52.0% under 0.16.1)
and base scored 6.0% under both.
