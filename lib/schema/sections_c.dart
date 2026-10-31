import 'package:flutter/material.dart';

import 'types.dart';

// 6. MONEY -------------------------------------------------------------------
final Sect sMoney = Sect(
  'money', 'Money', Icons.account_balance_wallet_outlined, const Color(0xFF5E9B43),
  'Income, spending, savings, bills, debts',
  [
    PageDef('cashflow', 'Income & expenses', Icons.swap_vert, [
      G('income', 'Income', [
        txt('source', 'Source'),
        one('type', 'Type', ['salary', 'freelance or business', 'gift', 'refund', 'interest or dividends', 'sale', 'other']),
        nbr('amount', 'Amount'),
        one('account', 'Account', ['cash', 'bank', 'wallet', 'other']),
      ], repeat: true, item: 'Income'),
      G('expenses', 'Expenses', [
        txt('item', 'Item'),
        one('cat', 'Category', [
          'food', 'groceries', 'transport', 'rent', 'bills and utilities', 'health',
          'education', 'shopping', 'entertainment', 'subscriptions', 'gifts or charity',
          'family', 'personal care', 'travel', 'debt payment', 'other',
        ]),
        nbr('amount', 'Amount'),
        one('method', 'Payment method', ['cash', 'debit card', 'credit card', 'bank transfer', 'wallet or UPI', 'other']),
        one('need', 'Need or want', ['need', 'want']),
        one('planned', 'Planned or impulse', ['planned', 'impulse']),
        one('mood', 'Mood at purchase', emotions),
        one('who', 'For whom', ['me', 'family', 'friend', 'shared', 'work']),
        yn('recurring', 'Recurring'),
        yn('regret', 'I regret this purchase'),
      ], repeat: true, item: 'Expense'),
      G('totals', 'Daily totals', [
        calc('income', 'Total income'),
        calc('spent', 'Total spent'),
        calc('net', 'Net for the day'),
        calc('budget', 'Daily budget'),
        calc('remaining', 'Remaining'),
        calc('impulse', 'Impulse total'),
        calc('bycat', 'Spending by category'),
        calc('nospend', 'No-spend day'),
        yn('nospend_override', 'No-spend day (override)'),
      ]),
    ]),
    PageDef('savings', 'Savings & debts', Icons.savings_outlined, [
      G('saved', 'Saved & invested', [
        one('type', 'Type', ['savings', 'emergency fund', 'investment', 'goal fund', 'retirement', 'giving']),
        nbr('amount', 'Amount'),
        txt('where', 'Where'),
      ], repeat: true, item: 'Saving'),
      G('debts', 'Debts & lending', [
        lnk('person', 'Person', 'people'),
        one('dir', 'Direction', ['I owe', 'owed to me']),
        nbr('amount', 'Amount'),
        dt('due', 'Due date'),
        nbr('paid', 'Paid so far'),
      ], repeat: true, item: 'Debt'),
    ]),
    PageDef('bills', 'Bills due', Icons.receipt_long_outlined, [
      G('due', 'Next 7 days', [], block: 'bills'),
    ]),
    PageDef('mindset', 'Money mindset', Icons.account_balance_outlined, [
      G('main', 'Mindset', [
        scale('stress', 'Money stress', worst: true),
        lnk('goal', 'Financial goal', 'goals'),
        nbr('goal_pct', 'Financial goal progress', unit: '%'),
        txt('lesson', 'Money lesson or decision'),
        nbr('balance', 'Balance snapshot'),
      ]),
      G('big', 'Big purchase being considered', [
        txt('item', 'Item'),
        nbr('price', 'Price'),
        dt('decide', 'Date to decide'),
      ], repeat: true, item: 'Purchase'),
    ]),
  ],
);

// 7. RELATIONSHIPS & SOCIAL --------------------------------------------------
final Sect sSocial = Sect(
  'social', 'Relationships', Icons.people_outline, const Color(0xFFD4687F),
  'People, conversations, boundaries, upkeep',
  [
    PageDef('people', 'Interactions', Icons.forum_outlined, [
      G('interactions', 'Interactions', [
        lnk('person', 'Person', 'people'),
        one('rel', 'Relationship', [
          'family', 'partner', 'friend', 'colleague', 'mentor', 'client', 'neighbor',
          'stranger', 'online contact',
        ]),
        one('mode', 'Mode', ['in person', 'call', 'video', 'message', 'email', 'social media', 'group']),
        dur('dur', 'Duration'),
        one('started', 'Started by', ['me', 'them', 'mutual']),
        txt('topic', 'Topic'),
        long('what', 'What happened'),
        scale('quality', 'Quality'),
        one('effect', 'Effect on me', ['charged', 'neutral', 'drained']),
        txt('follow', 'Follow-up needed'),
      ], repeat: true, item: 'Interaction'),
    ]),
    PageDef('daysocial', 'Day summary', Icons.groups_outlined, [
      G('summary', 'Day summary', [
        calc('with_people', 'Time with people'),
        nbr('alone', 'Time alone', unit: 'h'),
        one('energy', 'Social energy', ['charged', 'neutral', 'drained']),
        dur('family', 'Family time'),
        yn('quality_time', 'Quality time given to someone I love'),
        yn('reached_out', 'I reached out first today'),
      ]),
      G('giving', 'Giving & receiving', [
        txt('kind_did', 'Kind thing I did'),
        txt('kind_got', 'Kind thing I received'),
        txt('sup_gave', 'Support I gave'),
        txt('sup_got', 'Support I received'),
        yn('appreciated', 'Appreciation expressed'),
      ]),
    ]),
    PageDef('conflict', 'Conflict & boundaries', Icons.swap_horiz, [
      G('items', 'Conflicts', [
        lnk('who', 'With whom', 'people'),
        txt('cause', 'Cause'),
        txt('mine', 'My part'),
        one('handled', 'How I handled it', ['calm talk', 'avoided it', 'argued', 'apologized', 'waited']),
        one('resolved', 'Resolved', ['yes', 'in progress', 'no']),
        txt('boundary_set', 'Boundary I set'),
        txt('boundary_missed', 'Boundary I missed'),
        txt('apology', 'Apology owed'),
      ], repeat: true, item: 'Conflict'),
    ]),
    PageDef('upkeep', 'Connection upkeep', Icons.cake_outlined, [
      G('info', 'Coming up', [calc('birthdays', 'Upcoming birthdays or occasions')]),
      G('reach', 'People to reach out to', [
        lnk('person', 'Person', 'people'),
        txt('reason', 'Reason'),
        dt('by', 'By when'),
      ], repeat: true, item: 'Person'),
      G('promises', 'Promises I made', [
        txt('what', 'What'),
        lnk('to', 'To whom', 'people'),
        dt('by', 'By when'),
      ], repeat: true, item: 'Promise'),
      G('replies', 'Messages pending a reply', [
        lnk('person', 'Person', 'people'),
        txt('topic', 'Topic'),
      ], repeat: true, item: 'Message'),
    ]),
  ],
);

// 8. HABITS & ROUTINES -------------------------------------------------------
final Sect sHabits = Sect(
  'habits', 'Habits & Routines', Icons.repeat, const Color(0xFFE0843A),
  'Daily checklist, screen time, build and break',
  [
    PageDef('hab_daily', 'Daily checklist', Icons.check_circle_outline, [
      G('main', 'Default habits', [
        nbr('prayer', 'Prayer', unit: 'times'),
        yn('prayer_ontime', 'Prayer on time'),
        dur('reading', 'Reading'),
        calc('walk', 'Walking or exercise'),
        calc('water', 'Water target met'),
        calc('screen', 'Screen time under limit'),
        calc('skill', 'Skill practice'),
        yn('journal', 'Journal or gratitude'),
        calc('slept', 'Slept on time'),
        calc('woke', 'Woke on time'),
        dur('stretch', 'Stretching'),
        dur('meditate', 'Meditation or breathing'),
        dur('sunlight', 'Sunlight'),
        yn('nophone', 'No phone in first hour'),
        yn('planned', 'Planned tomorrow'),
        yn('tidied', 'Tidied up'),
      ]),
      G('custom', 'My own habits', [], block: 'custom_habits'),
      G('streaks', 'Streaks', [], block: 'streaks'),
    ]),
    PageDef('screen', 'Screen time', Icons.smartphone, [
      G('main', 'Screen time', [
        nbr('total', 'Total screen time', unit: 'h'),
        calc('limit', 'Daily limit'),
        calc('under', 'Under limit'),
        nbr('pickups', 'Phone pickups'),
        nbr('social', 'Social media', unit: 'h'),
        nbr('ent', 'Entertainment', unit: 'h'),
        nbr('prod', 'Productive use', unit: 'h'),
        tm('first', 'First screen after waking'),
        tm('last', 'Last screen before bed'),
        dur('late', 'Late-night scrolling'),
        txt('main', 'Main app today'),
        scale('urge', 'Urge to scroll', worst: true),
      ]),
    ]),
    PageDef('building', 'Habit I am building', Icons.trending_up, [
      G('items', 'Building', [
        lnk('habit', 'Habit', 'habits'),
        txt('why', 'Why it matters'),
        txt('cue', 'Cue or trigger'),
        yn('tiny', 'Tiny version done'),
        scale('difficulty', 'Difficulty today', worst: true),
        txt('reward', 'Reward'),
        many('missed', 'If missed, why', [
          'forgot', 'tired', 'busy', 'unmotivated', 'sick', 'travel', 'environment', 'other',
        ]),
      ], repeat: true, item: 'Habit'),
      G('streaks', 'Streaks', [], block: 'build_streaks'),
    ]),
    PageDef('breaking', 'Habit I am breaking', Icons.do_not_disturb_on_outlined, [
      G('items', 'Breaking', [
        lnk('habit', 'Habit', 'habits'),
        txt('why', 'Why I want to stop'),
        nbr('urges', 'Urges today', unit: 'count'),
        scale('strongest', 'Strongest urge', worst: true),
        many('triggers', 'Triggers', [
          'boredom', 'stress', 'tiredness', 'loneliness', 'a place', 'certain people',
          'time of day', 'an emotion', 'other',
        ]),
        nbr('slips', 'Slips', unit: 'count'),
        txt('instead', 'What I did instead'),
        txt('tomorrow', 'What I will try tomorrow'),
      ], repeat: true, item: 'Habit'),
      G('clean', 'Days clean', [], block: 'clean'),
    ]),
    PageDef('routines', 'Routines', Icons.schedule, [
      G('main', 'Routines', [
        one('morning', 'Morning routine', ['done', 'partly', 'skipped']),
        one('evening', 'Evening routine', ['done', 'partly', 'skipped']),
        one('bedtime', 'Bedtime routine', ['done', 'partly', 'skipped']),
        txt('missed', 'Routine steps missed'),
      ]),
    ]),
  ],
);

// 9. ACTIVITIES & EXPERIENCES ------------------------------------------------
final Sect sActivities = Sect(
  'activities', 'Activities', Icons.explore_outlined, const Color(0xFFA64F8E),
  'What happened, new things, practice, memories',
  [
    PageDef('major', 'Major activities', Icons.event_outlined, [
      G('items', 'Activities', [
        txt('activity', 'Activity'),
        one('planned', 'Planned or unplanned', ['planned', 'unplanned']),
        many('cat', 'Category', [
          'work', 'study', 'social', 'family', 'health', 'fun', 'errand', 'creative',
          'spiritual', 'travel', 'other',
        ]),
        tm('start', 'Start time'),
        tm('end', 'End time'),
        txt('where', 'Where'),
        lnk('with', 'With whom', 'people'),
        scale('outcome', 'Outcome'),
        one('effect', 'Effect on my energy', ['gave energy', 'neutral', 'took energy']),
        one('worth', 'Worth the time', ['yes', 'partly', 'no']),
      ], repeat: true, item: 'Activity'),
    ]),
    PageDef('unexpected', 'Unexpected events', Icons.warning_amber_rounded, [
      G('items', 'Events', [
        txt('what', 'What happened'),
        one('cat', 'Category', ['health', 'work', 'family', 'money', 'travel', 'tech', 'weather', 'social', 'other']),
        txt('cause', 'Cause'),
        dur('time', 'Time lost (-) or gained (+)', signed: true),
        nbr('money', 'Money impact', signed: true),
        txt('resp', 'How I responded'),
        scale('mood', 'Effect on my mood'),
        txt('learned', 'What I learned'),
        txt('different', 'What I would do differently'),
      ], repeat: true, item: 'Event'),
    ]),
    PageDef('gaps', 'Gap-filling', Icons.hourglass_empty, [
      G('items', 'Gaps between tasks', [
        tm('start', 'Start'),
        tm('end', 'End'),
        dur('dur', 'Duration'),
        txt('what', 'What I did'),
        one('cat', 'Category', ['productive', 'rest', 'social', 'digital', 'errand']),
        scale('helpful', 'Helpful'),
        one('trigger', 'What triggered it', ['boredom', 'waiting', 'tired', 'avoiding a task', 'habit']),
        txt('instead', 'What I could do instead'),
      ], repeat: true, item: 'Gap'),
      G('totals', 'Totals', [
        calc('common', 'Most common gap activity today'),
        calc('total', 'Total gap time'),
      ]),
    ]),
    PageDef('training', 'Training & practice', Icons.fitness_center, [
      G('items', 'Practice', [
        lnk('skill', 'Skill', 'skills'),
        txt('drill', 'Drill or practice'),
        nbr('volume', 'Volume'),
        txt('unit', 'Volume unit', hint: 'reps, pages, problems'),
        dur('time', 'Time'),
        scale('difficulty', 'Difficulty', worst: true),
        scale('quality', 'Quality or accuracy'),
        txt('improved', 'What improved'),
        txt('stuck', 'What is stuck'),
        txt('feedback', 'Feedback received'),
        txt('next', 'Next practice step'),
      ], repeat: true, item: 'Practice'),
    ]),
    PageDef('newthings', 'New things I tried', Icons.new_releases_outlined, [
      G('items', 'Tried', [
        txt('what', 'What'),
        one('cat', 'Category', ['food', 'place', 'activity', 'tool or app', 'skill', 'person', 'hobby', 'other']),
        scale('how', 'How it went'),
        txt('surprise', 'What surprised me'),
        one('again', 'Would I do it again', ['yes', 'maybe', 'no']),
      ], repeat: true, item: 'Try'),
    ]),
    PageDef('remember', 'Things to remember', Icons.bookmark_border, [
      G('items', 'Moments', [
        txt('moment', 'Moment'),
        lnk('who', 'Who was there', 'people'),
        txt('where', 'Where'),
        txt('why', 'Why it matters'),
        one('felt', 'How it felt', emotions),
        yn('fav', 'Favourite'),
      ], repeat: true, item: 'Moment'),
    ]),
    PageDef('timealloc', 'Time allocation', Icons.pie_chart_outline, [
      G('main', 'Where the 24 hours went', [
        calc('sleep', 'Sleep'),
        calc('work', 'Work'),
        calc('study', 'Study'),
        calc('exercise', 'Exercise'),
        nbr('meals', 'Meals', unit: 'h'),
        calc('family', 'Family and social'),
        nbr('rest', 'Rest and leisure', unit: 'h'),
        calc('screen', 'Screen and digital'),
        nbr('chores', 'Chores and errands', unit: 'h'),
        nbr('travel', 'Travel or commute', unit: 'h'),
        nbr('prayer', 'Prayer or reflection', unit: 'h'),
        nbr('other', 'Other', unit: 'h'),
        calc('total', 'Total'),
      ]),
    ]),
  ],
);
