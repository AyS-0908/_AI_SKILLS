# AUDIT_CHECKLIST

usage_contract:
  purpose: "GAS-only AUDIT risk scanner; use after normal code/spec review."
  use_rule: "Raise only evidence-backed issues found in the provided spec/code. Do not paste this checklist verbatim."
  depends_on: "Use SKILL.md for AUDIT output schema and global GAS priorities."
  exclude:
    - "Generic clean-code review"
    - "Generic JavaScript review"
    - "Copy-paste BUILD snippets"
    - "DEBUG probes or symptom diagnosis"
    - "Restating SKILL.md rules without project-specific evidence"

evidence_gate:
  issue_is_valid_only_if:
    - "The exact code/spec location, contract, or missing decision is identifiable."
    - "The failure mode is plausible for the declared Apps Script entrypoint."
    - "The fix is atomic and smaller than a rewrite."
  suppress_if:
    - "The risk is already handled by code, spec, deployment notes, or tests."
    - "The issue requires guessing sheet names, headers, scopes, quotas, users, or deployment settings."

scan:

  execution_context:
    ask:
      - "Is the entrypoint context explicit enough to validate active-file, event-object, and user-identity assumptions?"
      - "Does any standalone, trigger, or web-app path depend on active spreadsheet/sheet state that may not exist?"

  data_contract:
    ask:
      - "Are tab names, headers, statuses, IDs, property keys, and trigger names centralized and consistently consumed?"
      - "Can duplicate, blank, renamed, or user-reordered headers route data into the wrong column?"
      - "Are update targets based on stable IDs rather than mutable row position, unless row-position behavior is intentional?"

  sheets_io:
    ask:
      - "Can the computed read/write rectangle ever diverge from the array shape being read or written?"
      - "Can filters, sorting, manual row edits, or deleted rows make stored row indexes unsafe?"
      - "When output shrinks, is stale previous output intentionally cleared or preserved?"

  trigger_side_effects:
    ask:
      - "Can overlapping or repeated trigger runs duplicate irreversible effects: emails, API writes, appended rows, or status changes?"
      - "Is the chosen lock/state scope aligned with the shared resource being protected?"
      - "Is the processed/checkpoint marker written at a safe point relative to external side effects?"

  auth_identity_deployment:
    ask:
      - "Does the execution identity have access to every file, service, and external credential used by the flow?"
      - "Would a new service call require re-authorization, manifest scope review, or Advanced Service enablement?"
      - "For deployed surfaces, is the user-facing deployment/version the one being audited?"

  external_interfaces:
    ask:
      - "Can retry or re-run duplicate an external action?"
      - "Are secrets/config excluded from source, logs, sheet outputs, and client responses?"
      - "Is the external response contract validated before business logic trusts it?"

  scale_limits:
    ask:
      - "Which loop dominates Google-service or external-service calls as row/file/message volume grows?"
      - "Can a long run resume from a stored cursor/checkpoint without replaying completed side effects?"
      - "Is any cache used only for recomputable data, never as durable truth?"

  test_surface:
    ask:
      - "Is there a safe manual validation path for each real entrypoint: editor, trigger, menu, web app, or API call?"
      - "Can high-risk side effects run in dry-run/sample mode before touching production data?"

triage:
  P0:
    - "Likely data corruption, credential/secret exposure, unauthorized access, or unrecoverable duplicate external action."
  P1:
    - "Likely normal-path runtime failure, wrong-user failure, quota failure, deployment mismatch, or recurring duplicate processing."
  P2:
    - "Edge-case fragility, weak validation surface, maintainability blocker, or missing low-risk test coverage."

output_constraint:
  - "Use SKILL.md AUDIT schema."
  - "One issue = one atomic fix."
  - "Do not report checklist items that are not evidenced by the provided project."
