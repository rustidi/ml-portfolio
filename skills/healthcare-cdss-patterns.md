---
name: healthcare-cdss-patterns
description: Clinical Decision Support System (CDSS) engineering patterns — drug interaction checking, dose validation, clinical scoring (NEWS2/qSOFA/APACHE), alert severity classification, and integration into an EMR workflow. Safety-critical, zero-tolerance for false negatives.
triggers:
  - "drug interaction"
  - "CDSS"
  - "clinical score"
  - "interaction check"
  - "dose validation"
  - "NEWS2"
  - "qSOFA"
  - "clinical alert"
---

# Healthcare CDSS Development Patterns

Engineering patterns for building a Clinical Decision Support System. A CDSS augments clinician judgement with automated safety checks — it never replaces it. Prescribing decisions remain the clinician's responsibility; the system's job is to surface risks reliably and auditably.

## When to Activate

- Implementing drug interaction checking (including cross-checks against current medications and allergies)
- Dose validation engines for medication orders
- Clinical scoring systems (NEWS2, qSOFA, APACHE, GCS)
- Alert systems for abnormal clinical values
- Medication order entry with safety checks
- Lab result interpretation with clinical context

## Core Architecture

A CDSS engine is best built as a **pure function library with zero side effects**: input clinical data, output alerts. This makes it fully deterministic and exhaustively testable — the single most important property for a safety-critical system.

Three primary modules:

1. `checkInteractions(newDrug, currentMeds, allergies) -> InteractionAlert[]`
2. `validateDose(drug, dose, route, weight, age, renalFunction) -> DoseValidationResult`
3. `calculateNEWS2(vitals) -> NEWS2Result`

Keep the rules engine separate from data access and UI. Rules take plain value objects in and return plain alert/result objects out; adapters at the edges fetch the clinical data and render the alerts.

## Alert Severity Matrix

| Severity | UI Behavior | Clinician Action |
|----------|-------------|------------------|
| Critical | Block action. Non-dismissable modal. Red. | Must document override reason |
| Major | Warning banner inline. Orange. | Must acknowledge |
| Minor | Info note inline. Yellow. | Awareness only |

- Critical alerts must **not** auto-dismiss and must **not** be delivered as transient toast notifications.
- Every override of a Critical alert must capture a reason and write it to an audit trail.

## Safety Invariants

- **Zero tolerance for false negatives.** A missed interaction is far worse than a false positive. Test suites for CDSS logic should treat any false negative as a build-blocking failure (100% pass criteria on the critical safety category).
- **Deterministic rules.** The same clinical input must always produce the same alerts — no reliance on non-deterministic sources inside the rules engine.
- **Auditability.** Alert generation and clinician overrides are logged for later review.

## Related Concerns

- **EMR/EHR UI patterns** — where CDSS alerts surface in the encounter workflow (non-dismissable critical alerts, sticky patient header, accessibility for a clinical working environment).
- **Patient-safety eval harness** — a CRITICAL gate for CDSS accuracy that blocks deploy on any false negative.
- **PHI/PII compliance** — protecting patient data used as input to the CDSS.
