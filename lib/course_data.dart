import 'chord_data.dart';

enum LessonStage { foundations, mechanics, conversation }

enum LessonSkill { shift, enter, numbersAndSymbols, layoutSwitch }

enum LessonTopic { bilingual, links }

class TrainingLesson {
  const TrainingLesson({
    required this.id,
    required this.stage,
    required this.title,
    required this.focus,
    required this.target,
    this.skills = const <LessonSkill>{},
    this.topic,
  });

  final String id;
  final LessonStage stage;
  final String title;
  final String focus;
  final String target;
  final Set<LessonSkill> skills;
  final LessonTopic? topic;
}

class TrainingCourse {
  const TrainingCourse({
    required this.language,
    required this.lessons,
  });

  final CourseLanguage language;
  final List<TrainingLesson> lessons;

  Iterable<TrainingLesson> lessonsForStage(LessonStage stage) {
    return lessons.where((TrainingLesson lesson) => lesson.stage == stage);
  }

  Iterable<TrainingLesson> lessonsWithSkill(LessonSkill skill) {
    return lessons.where(
      (TrainingLesson lesson) => lesson.skills.contains(skill),
    );
  }
}

const List<TrainingCourse> courses = <TrainingCourse>[
  TrainingCourse(
    language: CourseLanguage.english,
    lessons: <TrainingLesson>[
      TrainingLesson(
        id: 'en-chat-01',
        stage: LessonStage.foundations,
        title: 'Core chords I',
        focus: 't e o a and Space',
        target: 'tea toe eat ate oat tea toe',
      ),
      TrainingLesson(
        id: 'en-chat-02',
        stage: LessonStage.foundations,
        title: 'Core chords II',
        focus: 'i n h s r l',
        target: 'this is a short line this is another short note',
      ),
      TrainingLesson(
        id: 'en-chat-03',
        stage: LessonStage.foundations,
        title: 'Everyday words',
        focus: 'u m d y g c w p k b f v',
        target: 'i am home and you can message me when you arrive',
      ),
      TrainingLesson(
        id: 'en-chat-04',
        stage: LessonStage.foundations,
        title: 'Rare letters',
        focus: 'j x z q and the full alphabet',
        target: 'quick brown fox jumps over the lazy dog',
      ),
      TrainingLesson(
        id: 'en-chat-05',
        stage: LessonStage.mechanics,
        title: 'Quick replies',
        focus: 'common one-to-one responses',
        target: 'yes no okay sure thanks maybe soon i am here',
      ),
      TrainingLesson(
        id: 'en-chat-06',
        stage: LessonStage.mechanics,
        title: 'Questions',
        focus: 'question marks and requests',
        target: 'are you home? when should we meet? can you call me?',
      ),
      TrainingLesson(
        id: 'en-chat-07',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift},
        title: 'Tone and punctuation',
        focus: 'direct punctuation and Shift pairs',
        target: 'Yes, that works. Wait: really? Great!',
      ),
      TrainingLesson(
        id: 'en-chat-08',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift},
        title: 'Names and Shift',
        focus: 'one-shot Shift and names',
        target: 'Hi Mia. I am with Alex. Are you free?',
      ),
      TrainingLesson(
        id: 'en-chat-09',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Message breaks',
        focus: 'Enter and two-person turns',
        target: 'Are you there?\nYes, I am here.',
      ),
      TrainingLesson(
        id: 'en-chat-10',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Time and numbers',
        focus: 'direct numbers-and-symbols layer in arrangements',
        target: 'Meet at 18:30 (gate 6)?\n'
            'Yes, bus 24 arrives at 18:20. Call +1-202-555-0167.',
      ),
      TrainingLesson(
        id: 'en-chat-11',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        topic: LessonTopic.links,
        title: 'Punctuation, handles, and links',
        focus: 'Shift pairs and the direct numbers-and-symbols layer',
        target: "Send Leo's file to @leo_home in #plans (fast) [safe].\n"
            'Open https://example.com/chat?room=plans&mode=work; re-check '
            'total=\$50+20%, x^2, a|b, path\\home, *today*, ~draft~, '
            '"ok", `raw`, {safe}, and 3<5>1!',
      ),
      TrainingLesson(
        id: 'en-chat-12',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Conversation rhythm',
        focus: 'short turns and a clear follow-up',
        target: 'Tell me when you arrive.\n'
            'Okay, I will send a quick message from the door.',
      ),
      TrainingLesson(
        id: 'en-chat-13',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Making plans',
        focus: 'a complete short exchange',
        target: 'Are you free after work?\n'
            'Yes, I can meet near the station at 19:00.\n'
            'Great, I will see you there.',
      ),
      TrainingLesson(
        id: 'en-chat-14',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Changing plans',
        focus: 'updates and a clear next action',
        target: 'My train is late, so I may need 15 more minutes.\n'
            'No problem. Send me a message when you leave the station, and I '
            'will wait by the cafe.',
      ),
      TrainingLesson(
        id: 'en-chat-15',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Clarifying details',
        focus: 'specific questions and a detailed answer',
        target: 'Should I bring the blue folder or the newer green one?\n'
            'Please bring the green folder. It has the final notes, the '
            'budget table, and the address we need.',
      ),
      TrainingLesson(
        id: 'en-chat-16',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Everyday update',
        focus: 'longer messages and follow-up',
        target: 'I finished the report and sent a copy to @mia. Could '
            'you check the last page tonight?\n'
            'Yes, I will read it after dinner. If anything looks unclear, I '
            'will list the questions here.',
      ),
      TrainingLesson(
        id: 'en-chat-17',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Supportive chat',
        focus: 'natural rhythm across three longer turns',
        target: 'Today was harder than I expected, and I still have two tasks '
            'left.\n'
            'Take a short break first. You already solved the difficult '
            'part, and the rest can wait until morning.\n'
            'Thanks. I needed to hear that.',
      ),
      TrainingLesson(
        id: 'en-chat-18',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Final conversation',
        focus: 'full layout in sustained one-to-one communication',
        target: 'Are we still cooking dinner at your place on Friday?\n'
            'Yes. I can buy vegetables and rice after work, but the '
            'market closes at 20:00.\n'
            'I will get bread, fruit, and something for dessert. Please '
            'send me the door code when you get home.\n'
            'Sure. If you arrive first, wait in the cafe across the street. I '
            'should be there by 19:15.\n'
            'Perfect. I will message you if my bus is late.',
      ),
    ],
  ),
  TrainingCourse(
    language: CourseLanguage.russian,
    lessons: <TrainingLesson>[
      TrainingLesson(
        id: 'ru-chat-01',
        stage: LessonStage.foundations,
        title: 'Основные аккорды I',
        focus: 'а о е т и пробел',
        target: 'ооо еее ааа ттт то та те от',
      ),
      TrainingLesson(
        id: 'ru-chat-02',
        stage: LessonStage.foundations,
        title: 'Основные аккорды II',
        focus: 'н и с р в л',
        target: 'верно она и он в лес они вели нас',
      ),
      TrainingLesson(
        id: 'ru-chat-03',
        stage: LessonStage.foundations,
        title: 'Повседневные слова',
        focus: 'к м у я д ь',
        target: 'я у дома мама дома как день',
      ),
      TrainingLesson(
        id: 'ru-chat-04',
        stage: LessonStage.foundations,
        title: 'Редкие буквы',
        focus: 'ё ж ш щ э ф ц ю й',
        target: 'ёж ждёт чай у школы щенок ищет мяч фея машет юле эхо '
            'звучит в цехе',
      ),
      TrainingLesson(
        id: 'ru-chat-05',
        stage: LessonStage.mechanics,
        title: 'Короткие ответы',
        focus: 'частые ответы в личной переписке',
        target: 'да нет хорошо ладно спасибо скоро буду я тут',
      ),
      TrainingLesson(
        id: 'ru-chat-06',
        stage: LessonStage.mechanics,
        title: 'Вопросы',
        focus: 'вопросительный знак и просьбы',
        target: 'ты дома? когда встретимся? можешь мне позвонить?',
      ),
      TrainingLesson(
        id: 'ru-chat-07',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift},
        title: 'Интонация и пунктуация',
        focus: 'прямые знаки и Shift-пары',
        target: 'Да, всё подходит. Подожди: правда? Отлично!',
      ),
      TrainingLesson(
        id: 'ru-chat-08',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift},
        title: 'Имена и Shift',
        focus: 'одноразовый Shift и имена',
        target: 'Привет, Маша. Я с Олегом. У подъезда. Ты свободна?',
      ),
      TrainingLesson(
        id: 'ru-chat-09',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Разделение сообщений',
        focus: 'Enter и реплики двух собеседников',
        target: 'Ты уже дома?\nДа, я только пришёл.',
      ),
      TrainingLesson(
        id: 'ru-chat-10',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Время и числа',
        focus: 'прямой слой цифр и символов в договорённостях',
        target: 'Встречаемся в 18:30 (у входа 6)?\n'
            'Да, автобус 24 будет в 18:20. Звони: +7-900-123-45-67.',
      ),
      TrainingLesson(
        id: 'ru-chat-11',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.layoutSwitch
        },
        topic: LessonTopic.bilingual,
        title: 'Переключение языка',
        focus: 'EN/RU внутри одного диалога',
        target: 'Напиши ready, когда будешь у входа.\n'
            'Хорошо, потом вернусь на русский.',
      ),
      TrainingLesson(
        id: 'ru-chat-12',
        stage: LessonStage.mechanics,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols,
          LessonSkill.layoutSwitch
        },
        topic: LessonTopic.links,
        title: 'Упоминания и ссылки',
        focus: 'Shift-пары и прямой слой цифр и символов',
        target: 'Отправь "черновик" для @oleg_home в #plans (важно).\n'
            'Открой https://example.com/chat?mode=work; отметь {готово}, '
            'сравни 3<5>1, напиши "да" и \'нет\', '
            'затем проверь слово-слово. Скидка 10%, итого 5*5=] готово.',
      ),
      TrainingLesson(
        id: 'ru-chat-13',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Договорённость о встрече',
        focus: 'короткий законченный диалог',
        target: 'Ты свободен после работы?\n'
            'Да, можем встретиться у станции в 19:00.\n'
            'Отлично, тогда увидимся там.',
      ),
      TrainingLesson(
        id: 'ru-chat-14',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Изменение планов',
        focus: 'обновление ситуации и следующее действие',
        target: 'Мой поезд задерживается, мне нужно ещё 15 минут.\n'
            'Ничего страшного. Напиши, когда выйдешь со станции, а я '
            'подожду у кафе.',
      ),
      TrainingLesson(
        id: 'ru-chat-15',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Уточнение деталей',
        focus: 'точный вопрос и подробный ответ',
        target: 'Мне принести синюю папку или новую зелёную?\n'
            'Пожалуйста, принеси зелёную. В ней итоговые заметки, '
            'таблица расходов и нужный нам адрес.',
      ),
      TrainingLesson(
        id: 'ru-chat-16',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.layoutSwitch
        },
        title: 'Повседневные новости',
        focus: 'длинные сообщения и обратная связь',
        target: 'Я закончил отчёт и отправил копию для @masha. Можешь '
            'вечером проверить последнюю страницу?\n'
            'Да, прочитаю после ужина. Если что-то будет непонятно, я '
            'напишу вопросы сюда.',
      ),
      TrainingLesson(
        id: 'ru-chat-17',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{LessonSkill.shift, LessonSkill.enter},
        title: 'Разговор с поддержкой',
        focus: 'естественный ритм трёх длинных реплик',
        target: 'День оказался сложнее, чем я ожидала, а у меня '
            'осталось ещё две задачи.\n'
            'Сначала немного отдохни. Самую трудную часть ты уже '
            'сделала, а остальное может подождать до утра.\n'
            'Спасибо. Мне важно было это услышать.',
      ),
      TrainingLesson(
        id: 'ru-chat-18',
        stage: LessonStage.conversation,
        skills: <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols
        },
        title: 'Итоговый диалог',
        focus: 'вся раскладка в продолжительном личном общении',
        target: 'Мы по-прежнему готовим ужин у тебя в пятницу?\n'
            'Да. После работы я куплю овощи и рис, но рынок закрывается '
            'в 20:00.\n'
            'Я возьму хлеб, фрукты и что-нибудь на десерт. Пришли код '
            'от двери, когда вернёшься домой.\n'
            'Хорошо. Если придёшь раньше, подожди в кафе через дорогу. Я буду '
            'примерно в 19:15.\n'
            'Отлично. Напишу тебе, если мой автобус задержится.',
      ),
    ],
  ),
];

TrainingCourse courseFor(CourseLanguage language) {
  return courses.firstWhere(
    (TrainingCourse course) => course.language == language,
  );
}
