# Personal onboarding and guidance

Implemented in Still 1.1, 29 September 2026. These are research-informed product choices, not a validated psychological questionnaire, a procrastination diagnosis, or evidence that Still itself improves outcomes.

## Evidence and limits

1. **Ryan and Deci (2000), Self-determination theory and the facilitation of intrinsic motivation, social development, and well-being.** American Psychologist, 55, 68–78. [Paper](https://selfdeterminationtheory.org/SDT/documents/2000_RyanDeci_SDT.pdf), [DOI](https://doi.org/10.1037/0003-066X.55.1.68). This theoretical review supports attention to autonomy, competence, and relatedness. Product interpretation: ask what the user values, preserve choice, and avoid assigning goals based on work or study status. This does not validate our exact wording or role choices.

2. **Sirois and Pychyl (2013), Procrastination and the Priority of Short-Term Mood Regulation: Consequences for Future Self.** Social and Personality Psychology Compass, 7, 115–127. [Author repository](https://eprints.whiterose.ac.uk/id/eprint/91793/), [DOI](https://doi.org/10.1111/spc3.12011). This conceptual review describes the role of aversive tasks and short-term mood regulation. Product interpretation: ask about a recent barrier without calling the user lazy or a procrastinator. Discomfort is one possible barrier; limited resources and changing priorities must remain legitimate answers. The app does not infer mental health conditions.

3. **Gollwitzer and Sheeran (2006), Implementation Intentions and Goal Achievement: A Meta-analysis of Effects and Processes.** Advances in Experimental Social Psychology, 38, 69–119. [DOI](https://doi.org/10.1016/S0065-2601(06)38002-1). Across 94 tests, the review reports benefits for goal attainment from linking situational cues with intended actions. Product interpretation: offer an optional when/if cue alongside the user's Next Move. This is a saved planning prompt, not an automated reminder or proof that any particular suggested action is effective.

4. **Gustavson and Miyake (2017), Academic procrastination and goal accomplishment: A combined experimental and individual differences investigation.** Learning and Individual Differences, 54, 160–172. [Paper](https://www.sciencedirect.com/science/article/pii/S1041608017300109), [DOI](https://doi.org/10.1016/j.lindif.2017.01.010). In 177 undergraduates over three weeks, the SMART-goal and implementation-intention interventions did not significantly reduce academic procrastination. This limits claims: a useful planning mechanism is not a guaranteed solution for procrastination, and findings in students do not establish effects in all life roles.

## Questions and concrete effects

All profile answers are optional. Users can skip the profile entirely, select multiple roles, edit answers in Settings, or clear them without deleting their board. No age, employer, school, diagnosis, or demographic inference is collected.

| Question | Effect |
|---|---|
| What is part of your life right now? | Supplies an example while writing a vision. Roles never restrict categories or assign priorities. Student plus professional receives a combined example. Other multiple selections use the first matching example rule in guidance.dart. |
| What would you like more room for? | Preselects the next vision's area. The user can change it. Learning / Study is now available to everyone. |
| When something matters, what can get in the way? | Supplies a default obstacle for new visions, which can be overridden for each vision. No scoring or personality labels. |
| What feels realistic for a small step? | Shows planning guidance for 5, 15, or 30 minutes, variable time, or no preference. These time options are design choices, not scientifically established optimal durations. No timers or deadlines are created. |
| What would be different in your life? Is this something you want for yourself? | Helps the user write their own reason. The app neither interprets nor scores free text. |
| What might get in the way? | Stores the explicitly chosen obstacle for this vision. Editable later in the Next Move help section. |
| When or if… | Stores an optional cue with a move; shown beside the current move on Today and detail. It remains attached to the historical move when replaced or completed. |

## Guidance mapping

Unclear starting point → identify one missing piece of information. Overwhelmed → reduce to the opening action. Waiting for perfection → try a private rough version. Distraction → choose a noticeable cue and reduce one distraction. Limited resources → acknowledge the constraint and offer preparation, support, or Later. Discomfort → notice the difficulty and choose a gentler entry. Uncertain personal meaning → reconsider whether the vision is still wanted.

Preset action examples first consider an explicit obstacle (meaning, resources, uncertainty, perfection, discomfort); otherwise they use the selected life area. These are editable examples, not advice inferred from the title. The app does not analyze free text, photos, or behavior. The user must explicitly insert and save a suggestion. It never completes, archives, or changes rhythm automatically.

## Tone explanations

Grounded offers calm, practical language. Motivational offers more energetic encouragement without pressure. Manifestation uses future-focused imagery paired with action; visualization is not represented as causing real-world outcomes. No Quotes uses factual Today text while keeping ordinary UI prompts. Each option has the actual Today copy as a preview in onboarding and Settings. These styles are preferences, not clinically matched interventions, and are never selected based on a barrier or role.

## Data and evaluation

Profile answers, vision obstacles, and action cues use the existing local store. No AI, cloud sync, or research analytics are introduced. Older saved boards receive empty defaults and retain their visions and history. Clearing profile answers does not erase previously saved vision obstacles or plans; the UI states this explicitly.

Tests cover legacy data, reload persistence, independent per-vision obstacles, failed writes, clearing profile answers, optional onboarding, narrow-screen multi-role selection, suggestion consent, cue saving, and tone descriptions. Further research should test comprehension and perceived pressure with actual users across life roles, then assess usefulness and follow-through; it should not treat time spent in the app or longer streaks as proof of benefit.
