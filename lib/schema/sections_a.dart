import 'package:flutter/material.dart';

import 'types.dart';

// 1. DAILY LOG ---------------------------------------------------------------
final Sect sDaily = Sect(
  'daily', 'Daily Log', Icons.wb_sunny_outlined, const Color(0xFFC9A65A),
  'Plan the day, reflect, set up tomorrow',
  [
    PageDef('daily', 'Plan & overview', Icons.wb_sunny_outlined, [
      G('main', 'Today', [
        calc('day', 'Day'),
        many('where', 'Location(s) today', ['home', 'office', 'outdoors', 'travel', 'other']),
        one('weather', 'Weather', ['sunny', 'cloudy', 'rainy', 'hot', 'cold', 'humid', 'stormy']),
        many('type', 'Type of day', [
          'work', 'study', 'rest', 'travel', 'social', 'family', 'errands',
          'sick or recovery', 'holiday or day off', 'event',
        ]),
        txt('event', 'Special occasion or event', hint: 'Birthday, appointment, deadline'),
        txt('focus', 'Day focus or intention (morning)'),
        one('feel', 'How I want to feel today', emotions),
        one('deep_time', 'Best time for my deep work today', partOfDay),
        scale('rating', 'Overall day rating'),
        txt('word', 'Day in one word'),
      ]),
      G('priorities', 'Top 3 priorities', [
        txt('p', 'Priority'),
        lnk('goal', 'Linked goal', 'goals+projects'),
        one('result', 'Result', ['done', 'partly done', 'not done']),
        one('why', 'If not done, why', notDoneWhy),
      ], repeat: true, max: 3, item: 'Priority'),
    ]),
    PageDef('reflect', 'End-of-day reflection', Icons.nights_stay_outlined, [
      G('main', 'Reflection', [
        long('did', 'What I did today'),
        txt('win', 'Biggest win'),
        txt('drain', 'Biggest drain'),
        txt('regret', 'Biggest mistake or regret'),
        long('well', 'What went well'),
        long('notwell', 'What did not go well'),
        long('differently', 'What I would do differently'),
        txt('decision', 'Biggest decision I made today'),
        txt('energizer', 'Moment that gave me energy'),
        txt('lesson', 'Lesson of the day'),
      ]),
    ]),
    PageDef('tomorrow', 'Tomorrow', Icons.event_available_outlined, [
      G('main', 'Set up tomorrow', [
        txt('first', 'First task for tomorrow'),
        txt('top', 'Top priority for tomorrow'),
        txt('avoid', 'One thing I will not do tomorrow'),
        many('prep', 'Preparation done', [
          'clothes ready', 'bag ready', 'schedule checked', 'alarm set',
          'tasks planned', 'meals planned',
        ]),
        calc('logcomp', 'Log completion'),
      ]),
    ]),
  ],
);

// 2. HEALTH & BODY -----------------------------------------------------------
final Sect sHealth = Sect(
  'health', 'Health & Body', Icons.favorite_border, const Color(0xFF2E9E83),
  'Sleep, food, gut, movement, symptoms',
  [
    PageDef('sleep', 'Sleep', Icons.bedtime_outlined, [
      G('main', 'Last night', [
        tm('target_bed', 'Target bedtime', def: 'bedtime'),
        tm('target_wake', 'Target wake time', def: 'wake'),
        tm('screens_off', 'Screens off at'),
        tm('last_meal', 'Last meal at'),
        tm('last_caf', 'Last caffeine at'),
        tm('bed', 'Went to bed at'),
        calc('on_target', 'Slept by target time'),
        dur('fall', 'Time to fall asleep'),
        tm('wake', 'Woke up at'),
        one('woke_by', 'Woke by', ['alarm', 'naturally', 'disturbed']),
        nbr('snooze', 'Snooze count'),
        calc('total', 'Total sleep'),
        calc('debt', 'Sleep debt vs target'),
        many('before', 'Activity before sleep', [
          'screen', 'reading', 'prayer', 'walk', 'work', 'talking', 'meal',
          'exercise', 'shower', 'meditation', 'nothing',
        ]),
        many('env', 'Sleep environment', [
          'dark', 'quiet', 'cool', 'comfortable', 'noise', 'light', 'too hot', 'too cold',
        ]),
        many('aids', 'Sleep aids', ['none', 'music', 'supplement', 'medicine', 'other']),
        one('dreams', 'Dreams', ['none', 'pleasant', 'neutral', 'disturbing']),
        one('groggy', 'Grogginess on waking', severity),
        yn('sunlight', 'Sunlight within an hour of waking'),
        scale('energy', 'Energy on waking'),
        scale('quality', 'Sleep quality'),
      ]),
      G('wakeups', 'Wake-ups during the night', [
        tm('time', 'Time'),
        dur('dur', 'Duration'),
        one('reason', 'Reason', [
          'bathroom', 'noise', 'thoughts', 'pain', 'heat or cold', 'thirst',
          'hunger', 'bad dream', 'unknown', 'other',
        ]),
      ], repeat: true, item: 'Wake-up'),
      G('naps', 'Naps', [
        tm('start', 'Start time'),
        dur('dur', 'Duration'),
        one('felt', 'Felt after', ['refreshed', 'neutral', 'groggier']),
      ], repeat: true, item: 'Nap'),
    ]),
    PageDef('meals', 'Meals & intake', Icons.restaurant_outlined, [
      G('meals', 'Meals', [
        one('type', 'Meal type', ['breakfast', 'lunch', 'dinner', 'snack', 'drink only']),
        tm('time', 'Time'),
        lnk('what', 'What I ate', 'foods'),
        one('portion', 'Portion', ['small', 'normal', 'large']),
        one('source', 'Source', ['home-cooked', 'restaurant', 'packaged', 'delivery']),
        one('healthy', 'Healthy', ['yes', 'partly', 'no']),
        many('how', 'Eaten how', ['sitting', 'on a screen', 'rushed', 'with others', 'alone']),
        one('why', 'Reason for eating', ['hunger', 'habit', 'boredom', 'stress', 'social', 'craving']),
        scale('hunger', 'Hunger before'),
        scale('full', 'Fullness after'),
        yn('planned', 'Planned ahead'),
      ], repeat: true, item: 'Meal'),
      G('summary', 'Daily intake summary', [
        calc('healthy_n', 'Healthy meals (out of 3)'),
        many('skipped', 'Skipped meals', ['breakfast', 'lunch', 'dinner']),
        one('overall', 'Hunger and fullness overall', ['normal', 'low', 'high']),
        calc('gap', 'Longest gap between meals'),
        yn('late', 'Late-night eating'),
        yn('fasting', 'Fasting today'),
        txt('fast_note', 'Fasting type and hours'),
        many('cravings', 'Cravings', ['sweet', 'salty', 'fried', 'caffeine', 'other']),
        nbr('fibre', 'Fibre, fruit or vegetables', unit: 'servings'),
        nbr('protein', 'Protein', unit: 'servings'),
        nbr('processed', 'Processed or fast food', unit: 'count'),
        nbr('fried', 'Fried or oily food', unit: 'count'),
        nbr('sugary', 'Sugary snacks or desserts', unit: 'count'),
      ]),
    ]),
    PageDef('hydration', 'Drinks & supplements', Icons.local_drink_outlined, [
      G('main', 'Hydration', [
        nbr('water', 'Water', unit: 'L'),
        calc('water_met', 'Water target met'),
        nbr('sugary_drinks', 'Sugary drinks', unit: 'count'),
        calc('caffeine', 'Total caffeine'),
      ]),
      G('drinks', 'Other drinks', [
        one('type', 'Type', ['tea', 'coffee', 'juice', 'soda', 'energy drink', 'milk', 'other']),
        nbr('count', 'Count'),
      ], repeat: true, item: 'Drink'),
      G('supps', 'Supplements and probiotics', [
        lnk('name', 'Name', 'meds'),
        txt('dose', 'Dose'),
        tm('time', 'Time'),
        yn('taken', 'Taken'),
      ], repeat: true, item: 'Supplement'),
      G('other', 'Tobacco, alcohol or other', [
        txt('type', 'Type'),
        txt('amount', 'Amount'),
        tm('time', 'Time'),
      ], repeat: true, module: 'intake', item: 'Entry'),
    ]),
    PageDef('gut', 'Gut health', Icons.healing_outlined, [
      G('bowel', 'Bowel movements', [
        tm('time', 'Time'),
        one('type', 'Consistency', [
          'Bristol 1', 'Bristol 2', 'Bristol 3', 'Bristol 4', 'Bristol 5',
          'Bristol 6', 'Bristol 7', 'normal', 'hard', 'loose', 'mixed',
        ]),
        one('colour', 'Colour', ['normal brown', 'light', 'dark', 'black', 'green', 'other']),
        one('ease', 'Ease', ['easy', 'mild effort', 'straining']),
        one('empty', 'Emptying', ['complete', 'incomplete']),
        one('urgency', 'Urgency', ['none', 'mild', 'urgent']),
        one('pain', 'Pain during', severity),
        one('blood', 'Blood or mucus seen', ['none', 'blood', 'mucus', 'both']),
      ], repeat: true, item: 'Bowel movement'),
      G('summary', 'Daily gut summary', [
        calc('count', 'Bowel movement count'),
        calc('days_since', 'Days since last bowel movement'),
        scale('comfort', 'Overall gut comfort'),
        yn('fermented', 'Probiotic or fermented food today'),
      ]),
      G('symptoms', 'Gut symptoms', [
        one('symptom', 'Symptom', [
          'bloating', 'gas', 'acidity or heartburn', 'reflux', 'stomach pain or cramps',
          'nausea', 'vomiting', 'belching', 'loose motion', 'constipation',
          'appetite loss', 'early fullness', 'other',
        ]),
        one('sev', 'Severity', severity),
        many('where', 'Where', ['upper', 'middle', 'lower', 'left', 'right', 'all over']),
        tm('start', 'Started at'),
        dur('last', 'Lasted'),
        lnk('meal', 'Linked meal', '@meals'),
        txt('trigger', 'Suspected trigger'),
        many('helped', 'What helped', ['walking', 'warm water', 'medicine', 'rest', 'nothing']),
      ], repeat: true, item: 'Symptom'),
    ]),
    PageDef('gutfood', 'Food reactions & urine', Icons.fastfood_outlined, [
      G('discomfort', 'Discomfort after meals', [
        lnk('meal', 'Which meal', '@meals'),
        nbr('after', 'Minutes after the meal', unit: 'min'),
        dur('how_long', 'How long it lasted'),
      ], repeat: true, item: 'Discomfort'),
      G('bad', 'Foods that seemed to cause a problem', [
        lnk('food', 'Food', 'foods'),
        txt('symptom', 'Symptom'),
      ], repeat: true, item: 'Food'),
      G('good', 'Foods that felt good', [
        lnk('food', 'Food', 'foods'),
      ], repeat: true, item: 'Food'),
      G('urine', 'Urine and hydration check', [
        nbr('count', 'Urination count'),
        one('colour', 'Colour', ['clear', 'light yellow', 'dark yellow', 'brown or red']),
        yn('burning', 'Burning or pain'),
        nbr('night', 'Night trips'),
      ]),
    ]),
    PageDef('move', 'Movement', Icons.directions_run, [
      G('sessions', 'Exercise sessions', [
        one('type', 'Type', [
          'walk', 'run', 'gym', 'yoga', 'stretching', 'cycling', 'swimming',
          'sport', 'home workout', 'other',
        ]),
        tm('start', 'Start time'),
        dur('dur', 'Duration'),
        scale('intensity', 'Intensity'),
        nbr('dist', 'Distance', unit: 'km'),
        one('where', 'Where', ['indoors', 'outdoors']),
        one('felt', 'Felt after', ['energised', 'okay', 'drained', 'sore']),
      ], repeat: true, item: 'Session'),
      G('summary', 'Daily movement summary', [
        nbr('steps', 'Steps'),
        calc('steps_met', 'Steps target met'),
        calc('active', 'Active minutes'),
        nbr('sitting', 'Sitting hours', unit: 'h'),
        nbr('breaks', 'Movement breaks', unit: 'count'),
        dur('stretch', 'Stretching or mobility'),
        dur('outdoor', 'Outdoors or sunlight'),
        yn('rest', 'Rest day'),
      ]),
      G('soreness', 'Soreness', [
        txt('part', 'Body part'),
        scale('sev', 'Severity', worst: true),
      ], repeat: true, item: 'Sore spot'),
    ]),
    PageDef('body', 'Body & symptoms', Icons.accessibility_new, [
      G('main', 'Body today', [
        scale('pe_m', 'Physical energy: morning'),
        scale('pe_a', 'Physical energy: afternoon'),
        scale('pe_e', 'Physical energy: evening'),
        scale('feel', 'Overall body feeling'),
        yn('ill', 'Signs of illness today'),
        many('hygiene', 'Hygiene and self-care', [
          'brushed teeth morning', 'brushed teeth night', 'shower', 'skincare', 'grooming',
        ]),
        long('side', 'Side effects noticed'),
      ]),
      G('symptoms', 'Symptoms', [
        one('symptom', 'Symptom', [
          'headache', 'body pain', 'joint pain', 'back or neck pain', 'eye strain',
          'sore throat', 'cough', 'cold or runny nose', 'fever', 'dizziness',
          'fainting', 'chest discomfort', 'shortness of breath', 'palpitations',
          'skin issue', 'swelling', 'fatigue', 'other',
        ]),
        txt('where', 'Where'),
        scale('sev', 'Severity', worst: true),
        tm('start', 'Started at'),
        dur('how_long', 'How long'),
        txt('trigger', 'Suspected trigger'),
        txt('helped', 'What helped'),
      ], repeat: true, item: 'Symptom'),
      G('vitals', 'Vitals (if measured)', [
        nbr('weight', 'Weight', unit: 'kg'),
        txt('bp', 'Blood pressure', hint: 'systolic / diastolic'),
        nbr('hr', 'Resting heart rate', unit: 'bpm'),
        nbr('temp', 'Temperature'),
        nbr('spo2', 'Oxygen saturation', unit: '%'),
        nbr('sugar', 'Blood sugar'),
        one('sugar_when', 'Blood sugar timing', ['fasting', 'after meal']),
        tm('measured', 'Time measured'),
      ]),
    ]),
    PageDef('meds', 'Medicines & follow-ups', Icons.medication_outlined, [
      G('meds', 'Medicines', [
        lnk('name', 'Name', 'meds'),
        txt('dose', 'Dose'),
        tm('scheduled', 'Scheduled time'),
        tm('taken_at', 'Taken at'),
        one('status', 'Status', ['taken', 'late', 'missed', 'skipped on purpose']),
        txt('why_missed', 'Reason if missed'),
      ], repeat: true, item: 'Medicine'),
      G('appts', 'Appointments', [
        dt('date', 'Date'),
        txt('who', 'Doctor or place'),
        txt('reason', 'Reason'),
      ], repeat: true, item: 'Appointment'),
      G('tests', 'Test pending or result due', [
        txt('test', 'Test'),
        dt('date', 'Date'),
      ], repeat: true, item: 'Test'),
      G('refill_g', 'Refill', [
        dt('refill', 'Refill due'),
      ]),
      G('questions', 'Questions to ask the doctor', [
        txt('q', 'Question'),
      ], repeat: true, item: 'Question'),
      G('cycle', 'Cycle tracking', [
        nbr('day', 'Cycle day'),
        one('flow', 'Flow', ['none', 'light', 'medium', 'heavy']),
        many('symptoms', 'Related symptoms', [
          'cramps', 'mood changes', 'fatigue', 'headache', 'bloating', 'other',
        ]),
      ], module: 'cycle'),
    ]),
  ],
);
