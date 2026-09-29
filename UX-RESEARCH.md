# Still 1.2 experience review

29 September 2026. The objective is a usable, honest mobile MVP with a focused first-use journey. “10/10” is an aspiration, not a measured score or a claim of accessibility conformance. The work below combines published design guidance, behavioral research from RESEARCH.md, implementation inspection, automated interaction checks, and rendered widget previews. It is not a substitute for observation of real users.

## Research findings and product decisions

| Evidence | Interpretation for Still | Implemented change |
|---|---|---|
| [GOV.UK: Structuring forms](https://www.gov.uk/service-manual/design/form-structure) recommends starting with one thing per page and using research to decide grouping. | A life-role question and a time-capacity question are different decisions. Present them separately. One field per page is not a universal rule for every editor. | Profile now asks one question at a time. Vision creation uses the same focused layout. |
| [GOV.UK: Designing good questions](https://www.gov.uk/service-manual/design/designing-good-questions) emphasizes asking only necessary questions and testing wording. | Do not make personal profiling a gate before creating a vision. Avoid identity labels or inferred diagnoses. | The primary welcome action creates a vision directly. Personalization is an optional alternative and remains in Settings. |
| [W3C WAI: Multi-page forms](https://www.w3.org/WAI/tutorials/forms/multi-page/) recommends orientation, logical stages, and progress information. | Progress must describe actual stages, including review, and remain understandable without color alone. | Numeric step count and semantic progress value. Profile has four questions plus review; vision creation has seven questions plus review. No fake percentage or unsupported completion-time promise. |
| [GOV.UK: Form-structure research](https://userresearch.blog.gov.uk/2015/08/13/no-more-accordions-how-to-choose-a-form-structure/) reports a case where removing progress indicators did not change completion. | A progress bar is navigation support, not evidence that this release will improve conversion. | We include progress at the user's request but also preserve answers, provide Back, and allow local draft resumption. |
| [GOV.UK: Check answers](https://design-system.service.gov.uk/patterns/check-answers/) supports reviewing and correcting before submission. | Users should not have to repeat an entire flow to fix one answer. | Review summaries with individual Change actions; editing returns directly to review. Saving the draft is distinct from committing a profile or creating a vision. |
| [Typeform: Progress bar](https://help.typeform.com/hc/en-us/articles/360051557892-Activate-the-Progress-bar) documents progress presentation in the reference product. | Borrow the focused interaction, not unverified claims that a Typeform-like interface always performs better. | Large answer cards, visible selection, explicit Continue, and no automatic navigation on selection. Multiple life roles remain possible. |
| [WCAG: Contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) sets 4.5:1 for ordinary text, with different rules for large text. | Muted copy must remain readable in light and dark themes. | New flow copy uses theme-specific foreground colors; labels use larger type and adaptive colors. New control colors are checked numerically in tests. Full legacy-screen contrast auditing remains separate. |
| [WCAG: Target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) specifies a 24 CSS-pixel minimum with defined exceptions. | Use larger practical targets on mobile instead of aiming for the minimum. | Answer cards are at least 60 logical pixels high; the Today move-edit target is enlarged to 48 by 48. |
| [WCAG: Focus not obscured](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html) addresses focused elements hidden by other content. | Actions and text fields must remain reachable when a keyboard or large text reduces available space. | Scrollable question body, separate action area, viewport resizing, visible keyboard focus from native Flutter controls, and narrow-screen/large-text checks. Browser and assistive-technology testing still required. |
| [W3C: Make each step clear](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o1p04-clear-steps/) supports orientation when attention is interrupted. | Returning should not require reconstructing completed answers. | Draft checkpoint on Continue, Back, and Save and close; resumption at the saved step. Draft save failures retain the visible answers and show an error. |

## Beyond the questionnaire

Today shows the latest saved Proof for the featured vision and a “Your direction” explanation for its chosen obstacle. These are the user's actual records plus disclosed preset guidance, not invented progress. A person without a profile can choose an optional four-question personalization path after creating a vision.

“Not today” now persists for that vision on the current local calendar date. It survives app reopening, has an Undo rest control, and expires the next day. It creates no notification, deletes no move, and awards no progress. The local day is based on the device clock.

Drafts and committed data remain local. Each kind has one resumable draft. Progress is saved when navigating through the flow or using Save and close; typing immediately before a browser refresh is not guaranteed to be retained. The UI states the checkpoint behavior. Completing a flow clears its draft in the same saved transaction. Old boards load with empty drafts and rest-state defaults.

## Acceptance checks

- Only the current onboarding question is rendered; selection never auto-advances.
- Numeric progress includes the review; the bar measures completed stages.
- Back preserves choices. Review edit returns directly to review.
- Empty required vision title gets an actionable error without discarding answers.
- Drafts survive a repository reload; failed saves do not publish partially changed state.
- Profile answers stay uncommitted until final confirmation.
- Old saved data loads without new fields. Saved profile or vision commits clear the matching draft only.
- Light and dark mobile previews, including 320-pixel width at 160% text scaling, are generated from actual Flutter widgets for visual inspection.
- Existing core journeys continue to pass before release deployment.

## What still needs real user validation

Recruit a small initial round across students, professionals, caregivers, and people with overlapping roles, including keyboard and screen-reader users. Ask them to create a personal vision, pause and resume, change a reviewed answer, record a real step, and return the next day. Observe completion without help, confusion about draft versus saved vision, perceived pressure, comprehension of tone, and whether suggestions are useful. Do not collect sensitive goal text merely for analytics.

Compare a shorter creation route with the seven-question route in a subsequent iteration. Treat completion and time-to-first-useful-plan as usability outcomes, not proof of improved life outcomes. Do not infer motivation from app-open frequency or introduce streak pressure.

Production gaps remain: cloud backup/sync, native reminders, real-device photo-picker verification, manual assistive-technology testing, and a wider audit of legacy screen typography. AI has not been added. The earlier behavioral evidence does not validate this exact questionnaire, nor does this release claim treatment of procrastination.
