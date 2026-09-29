import 'models.dart';

const lifeRoles = [
  'Student',
  'Working professional',
  'Self-employed / building a business',
  'Parent / caregiver',
  'Between roles',
  'Retired',
  'Something else',
];
const barriers = <String, String>{
  '': 'Not sure / prefer not to say',
  'unclear': 'I am not sure where to start',
  'overwhelmed': 'It feels too big',
  'perfection': 'I wait until I can do it well',
  'distraction': 'I get pulled into other things',
  'resources': 'Time, energy, money, or support is limited',
  'avoidance': 'I put it off when it feels uncomfortable',
  'meaning': 'I am not sure I still want this',
};
const capacities = <String, String>{
  '': 'Not sure yet',
  'small': 'About 5 minutes',
  'medium': 'About 15 minutes',
  'long': 'About 30 minutes',
  'variable': 'It varies a lot',
};

String toneDescription(Tone tone) => switch (tone) {
  Tone.grounded =>
    'Calm, practical encouragement. Focuses on what is manageable today.',
  Tone.motivational =>
    'More energetic encouragement. Invites action without streaks or guilt.',
  Tone.manifestation =>
    'Future-focused language. Imagines what matters, then pairs it with a practical step. Visualization does not guarantee an outcome.',
  Tone.none =>
    'Simple, factual wording. Removes inspirational Today text; ordinary prompts and confirmations remain.',
};
String toneExample(Tone tone) => switch (tone) {
  Tone.grounded => 'A little attention for what matters to you.',
  Tone.motivational => 'You’ve already started. One more small move.',
  Tone.manifestation => 'Picture it clearly. Take one step toward it.',
  Tone.none => 'Your visions and next moves.',
};
String visionExample(UserProfile p) {
  // Roles supply examples only; the user's chosen area always stays in control.
  if (p.roles.contains('Student') && p.roles.contains('Working professional')) {
    return 'Example: make room for learning alongside work. Or choose a hope outside both.';
  }
  if (p.roles.contains('Student')) {
    return 'Example: feel prepared for the next term. Your vision can also be about life outside studying.';
  }
  if (p.roles.contains('Working professional')) {
    return 'Example: build a skill or protect time outside work. Choose what matters to you.';
  }
  if (p.roles.contains('Parent / caregiver')) {
    return 'Example: make space for something of your own alongside caring for others.';
  }
  if (p.roles.contains('Self-employed / building a business')) {
    return 'Example: try one business idea without committing to a whole launch.';
  }
  if (p.roles.contains('Between roles')) {
    return 'Example: explore a direction at your own pace. It does not have to be about work.';
  }
  if (p.roles.contains('Retired')) {
    return 'Example: make room for a connection, interest, or experience you care about.';
  }
  return 'What would you like to experience, build, learn, or make more room for?';
}

String barrierHelp(String barrier) => switch (barrier) {
  'unclear' =>
    'Start by finding one missing piece of information. A question can be a useful first move.',
  'overwhelmed' =>
    'Choose just the opening action. You do not need to plan or finish the whole vision today.',
  'perfection' =>
    'Try a rough first version that only you need to see. Decide what is enough for this attempt.',
  'distraction' =>
    'Choose a cue you will notice and one distraction you can put aside for a short session.',
  'resources' =>
    'A real constraint is not a character flaw. Choose a no-cost preparation step, ask for support, or keep this in Later.',
  'avoidance' =>
    'Notice what feels uncomfortable without judging yourself. Choose a gentler opening step, or leave space for now.',
  'meaning' =>
    'Would you still choose this without anyone else expecting it? You can reshape the vision, put it in Later, or let it go.',
  _ =>
    'Choose one action you can actually do. You can change your plan whenever life changes.',
};
String capacityHelp(String capacity) => switch (capacity) {
  'small' =>
    'You chose about 5 minutes. Keep the step small enough to stop there.',
  'medium' => 'You chose about 15 minutes. Define one useful stopping point.',
  'long' =>
    'You chose about 30 minutes. Choose one focused piece, not the whole project.',
  'variable' =>
    'Your available time varies. Choose a small version you could do on a busy day.',
  _ => 'Choose a size that fits the time and energy you have today.',
};
String suggestedMove(String area, String barrier) {
  if (barrier == 'meaning') {
    return 'Write one sentence about whether I still want this.';
  }
  if (barrier == 'resources') {
    return 'Name one resource I need and one person or place I can ask.';
  }
  if (barrier == 'unclear') {
    return 'Write one question I need answered before I start.';
  }
  if (barrier == 'perfection') {
    return 'Make a rough first version of one small part.';
  }
  if (barrier == 'avoidance') {
    return 'Write what feels difficult and choose one gentler opening action.';
  }
  return switch (area) {
    'Learning / Study' =>
      'Open one topic and write down the first question I want to understand.',
    'Career / Business' =>
      'Write three rough points for one idea I want to explore.',
    'Travel' => 'Check the expiry date on my passport.',
    'Money' => 'Write down one expense I want to understand better.',
    'Relationships' =>
      'Draft a short message to someone I want to connect with.',
    'Home' => 'Choose one small space and put away three things.',
    'Health / Wellness' => 'Choose one manageable activity I would enjoy.',
    'Experiences' => 'Write down one experience I would like to try.',
    'Personal Growth' => 'Write one question about a skill I want to learn.',
    'How I Want Life to Feel' =>
      'Name one small thing that would make tomorrow feel calmer.',
    _ => 'Write down the first visible action I could take.',
  };
}
