import 'package:flutter/material.dart';

import 'types.dart';

// 3. MIND & MOOD -------------------------------------------------------------
final Sect sMind = Sect(
  'mind', 'Mind & Mood', Icons.self_improvement, const Color(0xFF8A6FD1),
  'Mood, energy, anxiety, stress, calm',
  [
    PageDef('checkins', 'Mood check-ins', Icons.mood, [
      G('checkins', 'Check-ins (up to 4 a day)', [
        one('part', 'Part of day', partOfDay),
        scale('mood', 'Mood'),
        many('emotions', 'Emotions', emotions),
        many('why', 'What influenced it', [
          'sleep', 'food', 'people', 'work', 'news', 'weather', 'thoughts', 'health', 'nothing clear',
        ]),
      ], repeat: true, max: 4, item: 'Check-in'),
    ]),
    PageDef('mind', 'Daily mind summary', Icons.psychology_outlined, [
      G('main', 'Summary', [
        scale('mood', 'Overall mood'),
        scale('happy', 'Happiness'),
        scale('calm', 'Calm'),
        scale('motivation', 'Motivation'),
        scale('confidence', 'Confidence'),
        scale('purpose', 'Sense of purpose'),
        scale('lonely', 'Loneliness', worst: true),
        one('irritable', 'Irritability', severity),
        one('selftalk', 'Self-talk', ['kind', 'neutral', 'harsh']),
        yn('mindful', 'I had a mindful moment today'),
      ]),
    ]),
    PageDef('energy', 'Energy & mental fatigue', Icons.bolt, [
      G('main', 'Energy', [
        scale('em', 'Mental energy: morning'),
        scale('ea', 'Mental energy: afternoon'),
        scale('ee', 'Mental energy: evening'),
        scale('fatigue', 'Mental fatigue', worst: true),
        one('peak', 'Fatigue peaked at', partOfDay),
        many('causes', 'Likely causes', [
          'poor sleep', 'long focus without breaks', 'too many decisions', 'multitasking',
          'screen overload', 'emotional strain', 'noise', 'meetings',
          'hunger or dehydration', 'no clear task', 'other',
        ]),
        one('fog', 'Brain fog', severity),
        scale('focus', 'Focus and clarity'),
        dur('longest', 'Longest focus stretch'),
        many('restored', 'What restored me', [
          'break', 'walk', 'nap', 'food or water', 'music', 'talking', 'nothing',
        ]),
      ]),
    ]),
    PageDef('anxiety', 'Anxiety', Icons.air, [
      G('main', 'Anxiety today', [
        scale('level', 'Anxiety level', worst: true),
        one('peak', 'Peaked at', partOfDay),
        txt('trigger', 'Trigger or situation'),
        many('topic', 'Topic', stressCauses),
        many('body', 'Body signs', [
          'fast heartbeat', 'tight chest', 'shallow breathing', 'shaking', 'sweating',
          'stomach upset', 'muscle tension', 'restlessness', 'dry mouth', 'dizziness',
        ]),
        many('thoughts', 'Thought patterns', [
          'overthinking', 'worst-case thinking', 'replaying the past', 'fear of the future',
          'self-criticism', 'comparing with others', 'need for certainty', 'avoidance',
        ]),
        dur('lasted', 'How long it lasted'),
        many('did', 'What I did', [
          'breathing', 'walk', 'prayer', 'talked to someone', 'music', 'writing',
          'distraction', 'avoided it', 'nothing',
        ]),
        scale('helped', 'Did it help'),
        txt('avoided', 'Something I avoided because of it'),
      ]),
    ]),
    PageDef('stress', 'Stress', Icons.speed, [
      G('main', 'Stress today', [
        scale('level', 'Stress level', worst: true),
        many('causes', 'Causes', stressCauses),
        txt('source', 'Main source'),
        one('control', 'How much is in my control', ['in my control', 'partly', 'not in my control']),
        many('signs', 'Stress signs', [
          'tension', 'headache', 'irritability', 'poor focus', 'low appetite', 'overeating',
          'sleep trouble', 'snapping at people', 'procrastinating',
        ]),
        txt('step', 'One step to reduce it'),
        one('recovered', 'Recovered by evening', ['yes', 'partly', 'no']),
      ]),
    ]),
    PageDef('calm', 'Calming practices', Icons.spa_outlined, [
      G('main', 'What helped me settle', [
        many('done', 'Practices done', [
          'breathing', 'meditation', 'prayer', 'walk', 'music', 'nature', 'journaling',
          'talking to someone', 'stretching', 'nap', 'shower', 'none',
        ]),
        dur('minutes', 'Minutes spent'),
      ]),
    ]),
    PageDef('positives', 'Positives & reflection', Icons.sentiment_satisfied_alt_outlined, [
      G('main', 'Positives', [
        txt('smile', 'Something that made me smile'),
        txt('drained', 'Something that drained me'),
        txt('proud', 'Something I am proud of'),
        txt('more_less', 'What I need more of or less of tomorrow'),
        long('journal', 'Short journal'),
      ]),
      G('gratitude', 'Gratitude (up to 3)', [
        txt('g', 'Grateful for'),
      ], repeat: true, max: 3, item: 'Gratitude'),
    ]),
  ],
);

// 4. IDEAVERSE ---------------------------------------------------------------
final Sect sIdeaverse = Sect(
  'ideaverse', 'Ideaverse', Icons.hub_outlined, const Color(0xFF4F6BED),
  'Ideas, thoughts, learnings, questions, linked together',
  [
    PageDef('iotd', 'Idea of the day', Icons.star_outline, [
      G('main', 'One pinned idea', [
        lnk('idea', 'Idea', '@ideas'),
        txt('why', 'Why this one'),
        scale('potential', 'Potential'),
        txt('step', 'First small step'),
      ]),
    ]),
    PageDef('ideas', 'Idea inbox', Icons.lightbulb_outline, [
      G('ideas', 'Ideas', [
        txt('title', 'Title'),
        long('details', 'Details'),
        one('cat', 'Category', [
          'business', 'app or tech', 'career', 'creative', 'health', 'money',
          'relationships', 'learning', 'lifestyle', 'fun or random', 'other',
        ]),
        one('from', 'Where it came from', [
          'own mind', 'conversation', 'book', 'video', 'social media', 'dream',
          'walking', 'work', 'other',
        ]),
        txt('problem', 'Problem it solves'),
        scale('excite', 'Excitement'),
        scale('effort', 'Effort', worst: true),
        one('mood', 'Mood when captured', emotions),
        one('status', 'Status', ['new', 'exploring', 'planned', 'in progress', 'done', 'parked', 'dropped']),
        txt('next', 'Next small action'),
        dt('review', 'Review date'),
        lnk('goal', 'Linked goal or project', 'goals+projects'),
        txt('related', 'Related ideas'),
      ], repeat: true, item: 'Idea',
          rowAction: const RowAction('Make it a task', Icons.checklist, 'tasks', 'tasks',
              {'next|title': 'task', 'goal': 'goal'}, extra: {'status': 'todo', 'group': 'should do'})),
    ]),
    PageDef('thoughts', 'Major thoughts', Icons.chat_bubble_outline, [
      G('items', 'Thoughts & realizations', [
        long('thought', 'Thought'),
        one('type', 'Type', [
          'insight', 'belief', 'decision', 'realization', 'fear', 'value', 'principle', 'perspective shift',
        ]),
        txt('trigger', 'What triggered it'),
        one('area', 'Life area', lifeArea),
        scale('importance', 'Importance'),
        scale('sure', 'How sure I am'),
        yn('changes', 'Changes what I will do'),
        txt('changes_what', 'If yes, what'),
        yn('principle', 'Save as a personal principle'),
      ], repeat: true, item: 'Thought'),
    ]),
    PageDef('stuck', 'Thoughts stuck in mind', Icons.loop, [
      G('items', 'Stuck thoughts', [
        long('thought', 'Thought'),
        one('theme', 'Theme', [
          'worry', 'regret', 'plan', 'replaying a conversation', 'fear', 'desire',
          'question', 'unfinished task', 'other',
        ]),
        nbr('times', 'Times it came back today'),
        scale('intensity', 'Intensity', worst: true),
        many('when', 'When it shows up', [
          'idle time', 'bedtime', 'after scrolling', 'during work', 'while eating', 'alone', 'with people',
        ]),
        one('feel', 'Feeling linked to it', emotions),
        txt('behind', 'What might be behind it'),
        yn('action', 'Is there an action I can take'),
        txt('action_what', 'If yes, what'),
        one('handled', 'How I handled it', [
          'wrote it down', 'took action', 'talked to someone', 'distracted myself',
          'let it go', 'ignored it', 'still stuck',
        ]),
        one('status', 'Status', ['active', 'easing', 'resolved']),
      ], repeat: true, item: 'Thought'),
    ]),
    PageDef('learned', 'New things I learned', Icons.school_outlined, [
      G('items', 'Learnings', [
        txt('what', 'What I learned'),
        txt('line', 'In one line (teach-back)'),
        txt('topic', 'Topic or field'),
        one('type', 'Type', ['fact', 'concept', 'skill', 'tip', 'lesson from a mistake', 'perspective']),
        one('source', 'Source', ['book', 'article', 'video', 'course', 'person', 'experience', 'mistake', 'other']),
        scale('understand', 'Understanding'),
        txt('use', 'How I will use it'),
        lnk('skill', 'Linked skill', 'skills'),
        one('revisit', 'Revisit', ['tomorrow', 'in 3 days', 'in a week', 'in a month', 'never']),
      ], repeat: true, item: 'Learning'),
    ]),
    PageDef('questions', 'Questions & curiosities', Icons.help_outline, [
      G('items', 'Questions', [
        txt('q', 'Question'),
        txt('why', 'Why it matters'),
        txt('where', 'Where to look'),
        one('status', 'Status', ['open', 'researching', 'answered']),
        long('answer', 'Answer'),
      ], repeat: true, item: 'Question'),
    ]),
    PageDef('quotes', 'Quotes & snippets', Icons.format_quote, [
      G('items', 'Quotes', [
        long('text', 'Text'),
        txt('source', 'Source'),
        txt('hit', 'Why it hit me'),
      ], repeat: true, item: 'Quote'),
    ]),
    PageDef('dump', 'Brain dump', Icons.inbox_outlined, [
      G('items', 'Unsorted notes', [
        long('notes', 'Unsorted notes', hint: 'Free space. Sort later.'),
        one('sort', 'Sort into', ['idea', 'thought', 'task', 'question', 'learning', 'nothing']),
      ], repeat: true, item: 'Dump'),
    ]),
    PageDef('verse', 'Ideaverse summary', Icons.hub_outlined, [
      G('main', 'Today in the verse', [
        calc('today', 'Entries captured today'),
        calc('old', 'Ideas still new after 7 days'),
        calc('stuck', 'Stuck thoughts still active'),
        calc('revisit', 'Revisits due today'),
      ]),
      G('review', 'Review old ideas', [], block: 'ideareview'),
    ]),
  ],
);

// 5. WORK & LEARNING ---------------------------------------------------------
final Sect sWork = Sect(
  'work', 'Work & Learning', Icons.work_outline, const Color(0xFF4C7A9E),
  'Tasks, focus, study, goals, blockers',
  [
    PageDef('tasks', 'Tasks', Icons.checklist, [
      G('carry', 'Carry over', [], block: 'carryover'),
      G('tasks', 'Tasks', [
        txt('task', 'Task'),
        one('group', 'Group', [
          'must do today', 'should do', 'nice to have', 'waiting on others', 'recurring', 'backlog',
        ]),
        one('cat', 'Category', [
          'work', 'study', 'career', 'personal', 'health', 'money or admin', 'home',
          'errands', 'social', 'creative',
        ]),
        one('prio', 'Priority', ['high', 'medium', 'low']),
        lnk('goal', 'Linked goal or project', 'goals+projects'),
        dt('due', 'Due date'),
        dur('est', 'Estimated time'),
        dur('actual', 'Actual time'),
        one('energy', 'Energy needed', ['high', 'medium', 'low']),
        one('where', 'Where', ['home', 'office', 'computer', 'phone', 'outside', 'anywhere']),
        one('status', 'Status', taskStatus),
        lnk('waiting', 'Waiting on', 'people'),
        one('why', 'If not done, why', [
          'ran out of time', 'low energy', 'blocked', 'unclear', 'distracted',
          'deprioritized', 'avoided', 'interrupted',
        ]),
        one('repeats', 'Repeats', ['no', 'daily', 'weekly', 'monthly']),
        long('subtasks', 'Subtasks', hint: 'One per line'),
        tm('reminder', 'Reminder'),
      ], repeat: true, item: 'Task'),
      G('totals', 'Task totals', [calc('totals', 'Today')]),
    ]),
    PageDef('focus', 'Focus sessions', Icons.center_focus_strong_outlined, [
      G('sessions', 'Sessions', [
        tm('start', 'Start time'),
        tm('end', 'End time'),
        lnk('task', 'Task', '@tasks'),
        one('type', 'Type', ['deep work', 'shallow or admin', 'meeting', 'study', 'creative', 'learning']),
        scale('quality', 'Focus quality'),
        nbr('distractions', 'Distractions', unit: 'count'),
        many('main', 'Main distraction', [
          'phone', 'social media', 'messages', 'noise', 'people', 'browser tabs',
          'my own thoughts', 'hunger or tiredness', 'none',
        ]),
        yn('break', 'Break taken'),
      ], repeat: true, item: 'Session'),
      G('totals', 'Totals', [calc('totals', 'Today')]),
    ]),
    PageDef('study', 'Study & skill practice', Icons.menu_book_outlined, [
      G('items', 'Study sessions', [
        lnk('skill', 'Skill', 'skills'),
        txt('topic', 'Topic'),
        one('resource', 'Resource', ['book', 'course', 'video', 'article', 'practice', 'mentor', 'other']),
        many('method', 'Method', ['read', 'watch', 'practice', 'teach', 'take notes', 'revise', 'project']),
        dur('time', 'Time'),
        scale('understand', 'Understanding'),
        txt('takeaway', 'Key takeaway'),
        txt('next', 'Next step'),
      ], repeat: true, item: 'Study'),
    ]),
    PageDef('output', 'Output & career', Icons.inventory_2_outlined, [
      G('produced', 'What I produced', [
        txt('item', 'Item'),
        one('type', 'Type', ['document', 'code', 'design', 'content', 'decision', 'client work', 'other']),
        nbr('qty', 'Quantity'),
      ], repeat: true, item: 'Output'),
      G('career', 'Career', [
        many('progress', 'Career progress today', [
          'applications sent', 'interviews', 'networking', 'portfolio work', 'certification',
          'skill milestone', 'pay or promotion talk', 'none',
        ]),
        scale('score', 'Career progress score'),
        long('notes', 'Career notes'),
      ]),
    ]),
    PageDef('goals', 'Goal progress', Icons.flag_outlined, [
      G('progress', 'Goals moved today', [
        lnk('goal', 'Goal', 'goals'),
        scale('moved', 'Moved forward by'),
        nbr('pct', 'Progress after today', unit: '%'),
        txt('what', 'What moved it'),
        txt('milestone', 'Next milestone'),
        one('on_track', 'On track', ['yes', 'at risk', 'no']),
      ], repeat: true, item: 'Goal'),
    ]),
    PageDef('blockers', 'Blockers & avoidance', Icons.block, [
      G('blockers', 'Blockers', [
        txt('b', 'Blocker'),
        one('type', 'Type', [
          'unclear next step', 'waiting on someone', 'missing tool or info', 'skill gap',
          'low energy', 'distraction', 'time', 'money', 'fear or doubt', 'other',
        ]),
        txt('action', 'Action to unblock'),
        txt('who', 'Who and by when'),
      ], repeat: true, item: 'Blocker'),
      G('avoid', 'Avoidance', [
        txt('what', 'Something I avoided today'),
        many('why', 'Why', [
          'boring', 'unclear', 'scary', 'tired', 'perfectionism', 'no deadline', 'too big', 'distracted',
        ]),
      ]),
    ]),
    PageDef('closeout', 'Close-out', Icons.task_alt, [
      G('main', 'End of work', [
        dur('wasted', 'Time wasted (estimate)'),
        scale('satisfaction', 'Work satisfaction'),
      ]),
      G('pending', 'Pending for tomorrow', [
        txt('t', 'Pending item'),
      ], repeat: true, item: 'Pending'),
    ]),
  ],
);
