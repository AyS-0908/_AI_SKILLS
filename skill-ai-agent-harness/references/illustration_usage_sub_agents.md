# Sub-Agents Usage

> Agent/tool names differ by product. Apply the rules; adapt the mechanism.

## Spawn Only When

Sub-agents are expensive: they start cold and re-derive context.

Spawn only when:
- Work has 2+ independent parts that can run in parallel.
- Search/scan output would pollute main context.
- A specialized agent clearly fits.

Do not spawn when:
- 1-3 direct tool calls solve it.
- Work is sequential.
- The request is vague. Scope the research and deliverable first.

Reuse before respawn: if a useful agent is running or just finished, continue it instead of starting another.

## Prompt Rules

Every prompt must be self-contained:
- Exact paths, constraints, and relevant context.
- What was tried or ruled out.
- Expected output format.
- No secrets or raw tokens.
- No "based on your findings, do X"; ask for findings, then synthesize in main context.

Main agent owns the final decision and final answer.

## Parallelism

If the tool supports parallel calls, send the whole batch at once.
Keep batches small and independent.

## Verification

After sub-agent edits:
- Read changed files directly.
- Run the smallest relevant check.
- Do not trust the self-summary.

## Isolation

For large independent implementation tasks in a git repo, use worktree isolation when available.
