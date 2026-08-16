export const meta = {
  name: 'agent-idiomize',
  description: 'Fan out Sonnet subagents to idiomize prepared Jac floor records (single-shot per batch)',
  phases: [{ title: 'Idiomize', detail: 'one Sonnet agent per batch, single-shot' }],
}

// args = { batch_dir, skill_path, n_batches, model }
const a = typeof args === 'string' ? JSON.parse(args) : args
const { batch_dir, skill_path, n_batches } = a
const model = a.model || 'sonnet'
log(`idiomizing ${n_batches} batches (single-shot, ${model}) from ${batch_dir}`)

const SCHEMA = {
  type: 'object',
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'integer' }, candidate: { type: 'string' } },
        required: ['id', 'candidate'],
      },
    },
  },
  required: ['candidates'],
}

const idx = Array.from({ length: n_batches }, (_, i) => i)

const results = await parallel(idx.map(i => () => {
  const bf = `${batch_dir}/batch${String(i).padStart(3, '0')}.json`
  return agent(
    `You are the idiomize step in a Jac dataset pipeline.\n\n` +
    `Read exactly TWO files, nothing else:\n` +
    `  1. rulebook (read once): ${skill_path}\n` +
    `  2. your batch: ${bf} — a JSON array of records, each ` +
    `{id, entrypoint, floor_fn (mechanical Jac), python (original)}.\n\n` +
    `Then in a SINGLE pass (do NOT run jac, do NOT Write any file), ` +
    `rewrite each record's floor_fn into idiomatic Jac per the rulebook above:\n` +
    `  - keep the function name (entrypoint) EXACTLY\n` +
    `  - valid Jac only (braces + semicolons, never Python colons)\n` +
    `  - replace Any/object with concrete types inferred from the python source\n` +
    `  - preserve behavior exactly; include any glob/import needed\n` +
    `  - NO test blocks, NO 'with entry', NO prose\n\n` +
    `Return {candidates: [{id, candidate}, ...]} — one entry per record, ` +
    `candidate = the raw idiomatic Jac (no markdown fences). That structured return ` +
    `IS your only output; you do not write any file.`,
    { label: `idiomize:b${i}`, phase: 'Idiomize', schema: SCHEMA, model }
  ).then(r => {
    const cs = (r && r.candidates) || []
    return { written: cs.length, ids: cs.map(c => c.id) }
  }).catch(() => ({ written: 0, ids: [] }))
}))

const total = results.filter(Boolean).reduce((n, r) => n + (r.written || 0), 0)
log(`done: ${total} candidates across ${n_batches} batches`)
return { n_batches, candidates_written: total }
