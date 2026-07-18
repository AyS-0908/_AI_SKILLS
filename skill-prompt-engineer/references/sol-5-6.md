# GPT-5.6 Sol

Apply this file only when the requested target is OpenAI GPT-5.6 Sol.

## Surface

- Write for the ChatGPT desktop or web composer.
- Exclude API fields, model slugs, caching, and programmatic tool instructions.
- Treat model, mode, and effort selection as UI choices outside the prompt. Do
  not add "use pro mode", "think harder", or similar instructions.

## GPT-5.6 adjustments

- Keep prompts lean and outcome-led. State each instruction once; remove roles,
  examples, reminders, and steps unless they change the result.
- Trust GPT-5.6 to infer routine methods. Describe the process only when its
  order, method, or approval point is itself a requirement.
- State the intended level of work and the few boundaries that prevent a real
  problem. IF the task may take actions -> distinguish drafting or inspection
  from changing, sending, publishing, purchasing, or deleting.
- IF an important ambiguity would materially change the result -> tell ChatGPT
  to ask one concise question. ELSE -> let it make and flag the smallest
  reasonable assumption.
- IF current or consequential facts matter -> ask ChatGPT to search the web and
  cite reliable sources. IF only supplied sources are allowed -> say so and
  require it to flag missing information instead of guessing.
- IF files, images, projects, or connected sources matter -> name what to use
  and what to extract. Do not prescribe every search or tool step.
- Specify audience, destination, required content, and useful omissions instead
  of relying on vague labels such as "concise", "friendly", or "professional".
- IF the work is important -> request one final check against the success
  criteria and require unverified facts or unresolved gaps to be flagged.

Use the shared output contract from `SKILL.md`.

## Official basis

- [GPT-5.6 prompting best practices](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6#prompting-best-practices)
- [Prompting in ChatGPT](https://learn.chatgpt.com/docs/prompting)
