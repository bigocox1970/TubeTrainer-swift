// All translatable website copy, keyed by locale. Adding a language = add a block
// here + a 3-line page under src/pages/<lang>/. The shared Home.astro + Base.astro
// render from this, so markup and CSS never duplicate.

export const locales = [
  { code: 'en', label: 'EN', name: 'English', home: '/' },
  { code: 'es', label: 'ES', name: 'Español', home: '/es/' },
  { code: 'pt-br', label: 'PT', name: 'Português', home: '/pt-br/' },
  { code: 'de', label: 'DE', name: 'Deutsch', home: '/de/' },
];

export const strings = {
  en: {
    meta: {
      title: 'TubeTrainer — Your coaches. Your exercises. Your progress.',
      description:
        'Save the best exercise coaching you find on YouTube and keep it right beside your workout. A premium, local-first gym tracker for iPhone. Free.',
    },
    nav: {
      coaching: 'Coaching', training: 'Training', screens: 'Screens',
      privacy: 'Privacy', faq: 'FAQ', download: 'Download', skip: 'Skip to content',
    },
    hero: {
      badge: 'Free · iPhone · No account',
      title: 'The best coaching on YouTube, right beside your workout.',
      lead: 'You already have coaches — they’re on YouTube. TubeTrainer turns that scattered coaching into your <strong>personal visual exercise manual</strong>, wrapped around a seriously fast gym tracker.',
      seeHow: 'See how it works',
      note: 'Free · iPhone · iOS 18+',
    },
    coaching: {
      eyebrow: 'The difference',
      title: 'Every exercise gets the coach who makes it click.',
      lead: 'One creator for bench, another for squats, another for mobility. Attach the exact video — or the exact moment — to any exercise. No blank rectangles: exercises without a coach show a discovery panel that makes building your library feel like collecting, not configuring.',
      ticks: [
        'Search YouTube or paste any link — even a Short.',
        'Save a start time so you jump straight to the useful part.',
        'Prioritise the trainers you already trust with favourite coaches.',
        'Compliant embedded playback with a clear “Open in YouTube”.',
      ],
    },
    logging: {
      eyebrow: 'Frictionless in the gym',
      title: 'Log a set in seconds. One hand. Every time.',
      lead: 'Big thumb-friendly controls, values pre-filled from last time, and a rest timer that starts itself. Watching the coach is always one tap away and never gets in the way of logging.',
      ticks: [
        '<strong>Last time</strong> is right there — no screen hopping.',
        'Tap to type or nudge with +/– . No hundred-value pickers.',
        'Complete a set → haptic → rest timer → next.',
        'Finish to a summary that celebrates real PRs.',
      ],
    },
    screens: {
      eyebrow: 'A look inside',
      title: 'Deliberately designed, top to bottom.',
      lead: 'Dark-first, with a proper light mode. Every screen earns its place.',
      hint: 'Swipe, scroll, or use the arrows →',
    },
    features: {
      eyebrow: 'Everything a serious log needs',
      title: 'A full-blooded tracker that happens to be free.',
      items: [
        { icon: 'library', title: 'A real exercise catalog', body: 'The best coaching on YouTube, right beside your workout. 50+ built-in movements across every muscle group, plus custom exercises. Forgiving search — type “RDL” and get Romanian Deadlift.' },
        { icon: 'chart', title: 'History & personal records', body: 'Every session saved. See last time before every set, track progression, and get honest PRs — heaviest set, estimated 1RM, best volume.' },
        { icon: 'timer', title: 'Rest timer that just works', body: 'Auto-starts on a completed set, counts down in the background, and notifies you when it’s time — even with the app closed.' },
        { icon: 'wifi', title: 'Works when the gym doesn’t', body: 'Terrible signal? Logging never blocks. If a video can’t load you still see last time, log sets, and finish — fully offline.' },
        { icon: 'lock', title: 'Yours, on your device', body: 'No account, no server, no analytics. Everything is local. Export a versioned backup whenever you like and restore it anywhere.' },
        { icon: 'bolt', title: 'Built to feel physical', body: 'Deliberate haptics, short natural animation, Dynamic Type and full dark & light themes. Fast where it counts.' },
      ],
    },
    share: {
      eyebrow: 'Share → TubeTrainer',
      title: 'Found a great video? Save it without leaving YouTube.',
      steps: [
        { title: 'Tap Share in YouTube', body: 'On any video or Short, TubeTrainer shows up in the share sheet like any other app.' },
        { title: 'Pick the exercise', body: 'Search your library right there and choose where it belongs.' },
        { title: 'It’s your coach', body: 'The video is waiting on that exercise next time you train. Done.' },
      ],
    },
    privacy: {
      eyebrow: 'Privacy by default',
      title: 'Your training stays on your phone.',
      lead: 'No account. No server. No analytics SDKs. TubeTrainer talks to YouTube only to find and play the coaching you choose — and never downloads or stores the video itself. Your workout history is yours, and you can export a versioned backup any time.',
    },
    faq: {
      eyebrow: 'Questions',
      title: 'Good to know.',
      items: [
        { q: 'Does it cost anything?', a: 'V1 is free. No subscription, no paywall, no account.' },
        { q: 'Do I need a YouTube account or API key?', a: 'No. You can paste any YouTube link or use “Search on YouTube” with zero setup. In-app search is optional and uses your own free YouTube API key if you add one.' },
        { q: 'Does it work offline?', a: 'The whole tracker works with no signal. Only playing an online video needs a connection — and if one fails, logging keeps working.' },
        { q: 'Are the videos stored on my phone?', a: 'Never. TubeTrainer saves only a reference (link, title, thumbnail) and plays videos through YouTube’s compliant player. It doesn’t download or rehost anything.' },
        { q: 'Can I move my data?', a: 'Yes — export a versioned JSON backup and import it to restore or move devices. Your library goes with you.' },
        { q: 'Which devices?', a: 'iPhone, iOS 18 and later. Dark and light themes included.' },
      ],
    },
    download: {
      eyebrow: 'Get the app',
      title: 'Be one of the first to train with it.',
      lead: 'TubeTrainer is on the App Store. Free, no account — download and start training.',
      sub: 'Download on the',
      note: 'Free · iPhone · iOS 18+',
    },
    footer: {
      tagline: 'Your coaches. Your exercises. Your progress.',
      madeFor: '© 2026 TubeTrainer. Made for lifters.',
      notAffiliated: 'Not affiliated with YouTube or Google.',
      privacy: 'Privacy Policy', terms: 'Terms of Use', support: 'Support',
    },
  },

  es: {
    meta: {
      title: 'TubeTrainer — Tus entrenadores. Tus ejercicios. Tu progreso.',
      description:
        'Guarda los mejores consejos de entrenadores de YouTube y tenlos junto a tus entrenamientos. Un tracker de gimnasio premium y local para iPhone. Gratis.',
    },
    nav: {
      coaching: 'Entrenadores', training: 'Entrenamiento', screens: 'Pantallas',
      privacy: 'Privacidad', faq: 'Preguntas frecuentes', download: 'Descargar', skip: 'Saltar al contenido',
    },
    hero: {
      badge: 'Gratis · iPhone · Sin cuenta',
      title: 'Los mejores entrenadores de YouTube, junto a tu entrenamiento.',
      lead: 'Ya tienes entrenadores: están en YouTube. TubeTrainer reúne sus mejores consejos en tu <strong>manual visual de ejercicios</strong>, integrado en un tracker de entrenamiento muy rápido.',
      seeHow: 'Mira cómo funciona',
      note: 'Gratis · iPhone · iOS 18+',
    },
    coaching: {
      eyebrow: 'La diferencia',
      title: 'Cada ejercicio tiene al entrenador que te lo hace entender.',
      lead: 'Un creador para el press de banca, otro para las sentadillas, otro para la movilidad. Adjunta el vídeo exacto —o el momento exacto— a cualquier ejercicio. Sin rectángulos vacíos: los ejercicios sin entrenador muestran un panel de descubrimiento que hace que crear tu biblioteca se sienta como coleccionar, no como configurar.',
      ticks: [
        'Busca en YouTube o pega cualquier enlace, incluso un Short.',
        'Guarda el punto de inicio para ir directamente a la parte útil.',
        'Prioriza a los entrenadores en los que ya confías marcándolos como favoritos.',
        'Reproducción integrada y conforme, con un claro “Abrir en YouTube”.',
      ],
    },
    logging: {
      eyebrow: 'Entrena sin complicaciones',
      title: 'Registra una serie en segundos. Con una mano. Siempre.',
      lead: 'Controles grandes pensados para el pulgar, valores rellenados desde la última vez y un temporizador de descanso que se inicia solo. Ver al entrenador está siempre a un toque y nunca estorba al registrar.',
      ticks: [
        'Tus <strong>datos de la última sesión</strong> están siempre a mano.',
        'Toca para escribir o ajusta con +/–. Sin interminables selectores de valores.',
        'Completa una serie → vibración → descanso → siguiente.',
        'Termina con un resumen que celebra tus récords reales (PR).',
      ],
    },
    screens: {
      eyebrow: 'Un vistazo por dentro',
      title: 'Diseñado con cuidado, de arriba abajo.',
      lead: 'Modo oscuro por defecto, con un modo claro de verdad. Cada pantalla se gana su sitio.',
      hint: 'Desliza, arrastra o usa las flechas →',
    },
    features: {
      eyebrow: 'Todo lo que necesita un registro serio',
      title: 'Un tracker de entrenamiento completo que, además, es gratis.',
      items: [
        { icon: 'library', title: 'Un catálogo de ejercicios de verdad', body: 'Más de 50 movimientos integrados para cada grupo muscular, y ejercicios personalizados. Búsqueda flexible: escribe “RDL” y aparece el Peso Muerto Rumano.' },
        { icon: 'chart', title: 'Historial y récords personales', body: 'Cada sesión guardada. Consulta la última vez antes de cada serie, sigue tu progresión y obtén PR honestos: serie más pesada, 1RM estimado, mejor volumen.' },
        { icon: 'timer', title: 'Un temporizador de descanso que funciona', body: 'Se inicia solo al completar una serie, cuenta atrás en segundo plano y te avisa cuando toca, incluso con la app cerrada.' },
        { icon: 'wifi', title: 'Funciona incluso sin cobertura', body: '¿Mala cobertura? Registrar nunca se bloquea. Si un vídeo no carga, sigues viendo la última vez, registras series y terminas, totalmente sin conexión.' },
        { icon: 'lock', title: 'Tuyo, en tu dispositivo', body: 'Sin cuenta, sin servidor, sin analíticas. Todo es local. Exporta una copia de seguridad con versiones cuando quieras y restáurala donde sea.' },
        { icon: 'bolt', title: 'Diseñado para sentirse natural', body: 'Vibraciones cuidadas, animación breve y natural, Dynamic Type y modos oscuro y claro completos. Rápido donde importa.' },
      ],
    },
    share: {
      eyebrow: 'Compartir → TubeTrainer',
      title: '¿Has encontrado un buen vídeo? Guárdalo sin salir de YouTube.',
      steps: [
        { title: 'Toca Compartir en YouTube', body: 'En cualquier vídeo o Short, TubeTrainer aparece en el menú de compartir como una app más.' },
        { title: 'Elige el ejercicio', body: 'Busca en tu biblioteca ahí mismo y elige a dónde va.' },
        { title: 'Ya es tu entrenador', body: 'El vídeo te espera en ese ejercicio la próxima vez que entrenes. Listo.' },
      ],
    },
    privacy: {
      eyebrow: 'Privacidad por defecto',
      title: 'Tu entrenamiento se queda en tu teléfono.',
      lead: 'Sin cuenta. Sin servidor. Sin SDK de analíticas. TubeTrainer se conecta a YouTube solo para encontrar y reproducir los vídeos de entrenamiento que elijas, y nunca descarga ni almacena el vídeo. Tu historial de entrenamiento es tuyo, y puedes exportar una copia de seguridad con versiones cuando quieras.',
    },
    faq: {
      eyebrow: 'Preguntas',
      title: 'Conviene saberlo.',
      items: [
        { q: '¿Cuesta algo?', a: 'La V1 es gratis. Sin suscripción, sin muro de pago, sin cuenta.' },
        { q: '¿Necesito una cuenta de YouTube o una clave API?', a: 'No. Puedes pegar cualquier enlace de YouTube o usar “Buscar en YouTube” sin configurar nada. La búsqueda dentro de la app es opcional y usa tu propia clave API gratuita de YouTube si añades una.' },
        { q: '¿Funciona sin conexión?', a: 'Todo el tracker funciona sin señal. Solo reproducir un vídeo online necesita conexión, y si falla, el registro sigue funcionando.' },
        { q: '¿Se guardan los vídeos en mi teléfono?', a: 'Nunca. TubeTrainer guarda solo una referencia (enlace, título, miniatura) y reproduce los vídeos con el reproductor oficial de YouTube. No descarga ni realoja nada.' },
        { q: '¿Puedo mover mis datos?', a: 'Sí: exporta una copia JSON con versiones e impórtala para restaurar o cambiar de dispositivo. Puedes llevarte tu biblioteca contigo.' },
        { q: '¿Qué dispositivos?', a: 'iPhone, iOS 18 o posterior. Con modos oscuro y claro.' },
      ],
    },
    download: {
      eyebrow: 'Consigue la app',
      title: 'Sé de los primeros en entrenar con ella.',
      lead: 'TubeTrainer ya está en la App Store. Gratis, sin cuenta: descárgala y empieza a entrenar.',
      sub: 'Descárgala en la',
      note: 'Gratis · iPhone · iOS 18+',
    },
    footer: {
      tagline: 'Tus entrenadores. Tus ejercicios. Tu progreso.',
      madeFor: '© 2026 TubeTrainer. Hecho para quienes entrenan en serio.',
      notAffiliated: 'Sin afiliación con YouTube ni Google.',
      privacy: 'Privacidad', terms: 'Términos de uso', support: 'Soporte',
    },
  },

  'pt-br': {
    meta: {
      title: 'TubeTrainer — Seus treinadores. Seus exercícios. Seu progresso.',
      description:
        'Salve as melhores dicas de exercícios que você encontra no YouTube e mantenha-as ao lado do seu treino. Um tracker de academia premium e local para iPhone. Grátis.',
    },
    nav: {
      coaching: 'Treinadores', training: 'Treino', screens: 'Telas',
      privacy: 'Privacidade', faq: 'Perguntas frequentes', download: 'Baixar', skip: 'Pular para o conteúdo',
    },
    hero: {
      badge: 'Grátis · iPhone · Sem conta',
      title: 'Os melhores treinadores do YouTube, ao lado do seu treino.',
      lead: 'Você já tem treinadores: eles estão no YouTube. O TubeTrainer reúne as melhores dicas deles no seu <strong>manual visual de exercícios</strong>, integrado a um tracker de treino muito rápido.',
      seeHow: 'Veja como funciona',
      note: 'Grátis · iPhone · iOS 18+',
    },
    coaching: {
      eyebrow: 'A diferença',
      title: 'Cada exercício ganha o treinador que faz tudo fazer sentido.',
      lead: 'Um criador para o supino, outro para o agachamento, outro para a mobilidade. Anexe o vídeo exato — ou o momento exato — a qualquer exercício. Sem retângulos vazios: exercícios sem treinador mostram um painel de descoberta que faz montar sua biblioteca parecer colecionar, não configurar.',
      ticks: [
        'Busque no YouTube ou cole qualquer link, até um Short.',
        'Salve o ponto de início para ir direto à parte útil.',
        'Priorize os treinadores em que você já confia marcando-os como favoritos.',
        'Reprodução incorporada e em conformidade, com um claro “Abrir no YouTube”.',
      ],
    },
    logging: {
      eyebrow: 'Sem atrito na academia',
      title: 'Registre uma série em segundos. Com uma mão. Sempre.',
      lead: 'Controles grandes pensados para o polegar, valores preenchidos da última vez e um timer de descanso que começa sozinho. Ver o treinador está sempre a um toque e nunca atrapalha o registro.',
      ticks: [
        'Seus <strong>dados da última sessão</strong> estão sempre à mão.',
        'Toque para digitar ou ajuste com +/–. Sem seletores intermináveis de valores.',
        'Complete uma série → vibração → descanso → próxima.',
        'Termine com um resumo que celebra seus recordes de verdade (PR).',
      ],
    },
    screens: {
      eyebrow: 'Uma espiada por dentro',
      title: 'Projetado com capricho, de cima a baixo.',
      lead: 'Modo escuro por padrão, com um modo claro de verdade. Cada tela merece seu lugar.',
      hint: 'Deslize, role ou use as setas →',
    },
    features: {
      eyebrow: 'Tudo o que um registro sério precisa',
      title: 'Um tracker de treino completo que, de quebra, é grátis.',
      items: [
        { icon: 'library', title: 'Um catálogo de exercícios de verdade', body: 'Mais de 50 movimentos integrados para cada grupo muscular, além de exercícios personalizados. Busca flexível: digite “RDL” e aparece o Levantamento Terra Romeno.' },
        { icon: 'chart', title: 'Histórico e recordes pessoais', body: 'Cada sessão salva. Veja a última vez antes de cada série, acompanhe a progressão e tenha PRs honestos: série mais pesada, 1RM estimado, melhor volume.' },
        { icon: 'timer', title: 'Um timer de descanso que funciona', body: 'Começa sozinho ao completar uma série, faz a contagem em segundo plano e avisa na hora certa — mesmo com o app fechado.' },
        { icon: 'wifi', title: 'Funciona mesmo sem sinal', body: 'Sinal ruim? O registro nunca trava. Se um vídeo não carregar, você ainda vê a última vez, registra séries e termina — totalmente offline.' },
        { icon: 'lock', title: 'Seu, no seu dispositivo', body: 'Sem conta, sem servidor, sem analytics. Tudo é local. Exporte um backup com versões quando quiser e restaure onde for.' },
        { icon: 'bolt', title: 'Feito para parecer natural', body: 'Vibrações caprichadas, animação breve e natural, Dynamic Type e modos escuro e claro completos. Rápido onde importa.' },
      ],
    },
    share: {
      eyebrow: 'Compartilhar → TubeTrainer',
      title: 'Achou um bom vídeo? Salve sem sair do YouTube.',
      steps: [
        { title: 'Toque em Compartilhar no YouTube', body: 'Em qualquer vídeo ou Short, o TubeTrainer aparece no menu de compartilhamento como qualquer outro app.' },
        { title: 'Escolha o exercício', body: 'Busque na sua biblioteca ali mesmo e escolha onde ele vai.' },
        { title: 'Já é seu treinador', body: 'O vídeo espera nesse exercício na próxima vez que você treinar. Pronto.' },
      ],
    },
    privacy: {
      eyebrow: 'Privacidade por padrão',
      title: 'Seu treino fica no seu celular.',
      lead: 'Sem conta. Sem servidor. Sem SDKs de analytics. O TubeTrainer se conecta ao YouTube apenas para encontrar e reproduzir os vídeos de treino que você escolher — e nunca baixa nem armazena o vídeo. Seu histórico de treino é seu, e você pode exportar um backup com versões quando quiser.',
    },
    faq: {
      eyebrow: 'Perguntas',
      title: 'Bom saber.',
      items: [
        { q: 'Custa alguma coisa?', a: 'A V1 é grátis. Sem assinatura, sem paywall, sem conta.' },
        { q: 'Preciso de conta do YouTube ou chave de API?', a: 'Não. Você pode colar qualquer link do YouTube ou usar “Buscar no YouTube” sem configurar nada. A busca dentro do app é opcional e usa sua própria chave de API gratuita do YouTube, se você adicionar uma.' },
        { q: 'Funciona offline?', a: 'Todo o tracker funciona sem sinal. Só reproduzir um vídeo online precisa de conexão — e se falhar, o registro continua funcionando.' },
        { q: 'Os vídeos ficam salvos no meu celular?', a: 'Nunca. O TubeTrainer salva apenas uma referência (link, título, miniatura) e reproduz os vídeos pelo player oficial do YouTube. Não baixa nem re-hospeda nada.' },
        { q: 'Posso mover meus dados?', a: 'Sim: exporte um backup JSON com versões e importe para restaurar ou trocar de dispositivo. Você leva sua biblioteca com você.' },
        { q: 'Quais dispositivos?', a: 'iPhone, iOS 18 ou posterior. Com modos escuro e claro.' },
      ],
    },
    download: {
      eyebrow: 'Baixe o app',
      title: 'Seja um dos primeiros a treinar com ele.',
      lead: 'O TubeTrainer já está na App Store. Grátis, sem conta: baixe e comece a treinar.',
      sub: 'Baixar na',
      note: 'Grátis · iPhone · iOS 18+',
    },
    footer: {
      tagline: 'Seus treinadores. Seus exercícios. Seu progresso.',
      madeFor: '© 2026 TubeTrainer. Feito para quem treina de verdade.',
      notAffiliated: 'Sem afiliação com o YouTube ou o Google.',
      privacy: 'Privacidade', terms: 'Termos de uso', support: 'Suporte',
    },
  },

  de: {
    meta: {
      title: 'TubeTrainer — Deine Trainer. Deine Übungen. Dein Fortschritt.',
      description:
        'Speichere die besten Übungs-Tipps, die du auf YouTube findest, und hab sie direkt neben deinem Workout. Ein hochwertiger, lokaler Gym-Tracker fürs iPhone. Kostenlos.',
    },
    nav: {
      coaching: 'Trainer', training: 'Training', screens: 'Screens',
      privacy: 'Datenschutz', faq: 'FAQ', download: 'Laden', skip: 'Zum Inhalt springen',
    },
    hero: {
      badge: 'Kostenlos · iPhone · Kein Konto',
      title: 'Die besten Trainer auf YouTube, direkt neben deinem Workout.',
      lead: 'Du hast schon Trainer – sie sind auf YouTube. TubeTrainer bündelt ihre besten Tipps in deinem <strong>visuellen Übungshandbuch</strong>, eingebettet in einen richtig schnellen Gym-Tracker.',
      seeHow: 'So funktioniert’s',
      note: 'Kostenlos · iPhone · iOS 18+',
    },
    coaching: {
      eyebrow: 'Der Unterschied',
      title: 'Jede Übung bekommt den Trainer, der sie erklärt.',
      lead: 'Ein Creator fürs Bankdrücken, einer für Kniebeugen, einer für Mobilität. Häng das genaue Video – oder den genauen Moment – an jede Übung. Keine leeren Kacheln: Übungen ohne Trainer zeigen ein Entdeckungs-Panel, das den Aufbau deiner Bibliothek wie Sammeln wirken lässt, nicht wie Konfigurieren.',
      ticks: [
        'Suche auf YouTube oder füge jeden Link ein – auch einen Short.',
        'Speichere einen Startpunkt, um direkt zum nützlichen Teil zu springen.',
        'Priorisiere die Trainer, denen du schon vertraust, als Favoriten.',
        'Regelkonforme eingebettete Wiedergabe mit klarem „In YouTube öffnen“.',
      ],
    },
    logging: {
      eyebrow: 'Reibungslos im Gym',
      title: 'Einen Satz in Sekunden loggen. Einhändig. Jedes Mal.',
      lead: 'Große, daumenfreundliche Bedienelemente, Werte vom letzten Mal vorausgefüllt und ein Pausen-Timer, der von selbst startet. Den Trainer anzusehen ist immer nur einen Tipp entfernt und stört nie beim Loggen.',
      ticks: [
        'Deine <strong>Daten der letzten Einheit</strong> sind immer griffbereit.',
        'Tippen zum Eingeben oder mit +/– anpassen. Keine endlosen Werteräder.',
        'Satz abschließen → Haptik → Pause → weiter.',
        'Zum Schluss eine Übersicht, die echte PRs feiert.',
      ],
    },
    screens: {
      eyebrow: 'Ein Blick nach innen',
      title: 'Bewusst gestaltet, von oben bis unten.',
      lead: 'Dark-Mode zuerst, mit einem echten Light-Mode. Jeder Screen verdient seinen Platz.',
      hint: 'Wischen, scrollen oder die Pfeile nutzen →',
    },
    features: {
      eyebrow: 'Alles, was ein ernsthaftes Log braucht',
      title: 'Ein vollwertiger Tracker, der obendrein kostenlos ist.',
      items: [
        { icon: 'library', title: 'Ein echter Übungskatalog', body: 'Über 50 integrierte Übungen für jede Muskelgruppe, plus eigene Übungen. Tolerante Suche: Tippe „RDL“ und du bekommst Rumänisches Kreuzheben.' },
        { icon: 'chart', title: 'Verlauf & persönliche Rekorde', body: 'Jede Einheit gespeichert. Sieh vor jedem Satz das letzte Mal, verfolge den Fortschritt und bekomme ehrliche PRs – schwerster Satz, geschätztes 1RM, bestes Volumen.' },
        { icon: 'timer', title: 'Ein Pausen-Timer, der einfach funktioniert', body: 'Startet automatisch bei einem abgeschlossenen Satz, zählt im Hintergrund herunter und benachrichtigt dich rechtzeitig – auch bei geschlossener App.' },
        { icon: 'wifi', title: 'Funktioniert, wenn das Gym es nicht tut', body: 'Schlechter Empfang? Das Loggen blockiert nie. Lädt ein Video nicht, siehst du trotzdem das letzte Mal, loggst Sätze und machst fertig – komplett offline.' },
        { icon: 'lock', title: 'Deins, auf deinem Gerät', body: 'Kein Konto, kein Server, keine Analytics. Alles ist lokal. Exportiere jederzeit ein versioniertes Backup und stelle es überall wieder her.' },
        { icon: 'bolt', title: 'Gebaut, um sich natürlich anzufühlen', body: 'Bewusste Haptik, kurze, natürliche Animationen, Dynamic Type und vollständige Dark- und Light-Themes. Schnell, wo es zählt.' },
      ],
    },
    share: {
      eyebrow: 'Teilen → TubeTrainer',
      title: 'Ein tolles Video gefunden? Speichere es, ohne YouTube zu verlassen.',
      steps: [
        { title: 'In YouTube auf Teilen tippen', body: 'Bei jedem Video oder Short taucht TubeTrainer im Teilen-Menü auf wie jede andere App.' },
        { title: 'Übung auswählen', body: 'Durchsuche deine Bibliothek direkt dort und wähle, wohin es gehört.' },
        { title: 'Das ist dein Trainer', body: 'Das Video wartet bei dieser Übung beim nächsten Training. Fertig.' },
      ],
    },
    privacy: {
      eyebrow: 'Datenschutz von Haus aus',
      title: 'Dein Training bleibt auf deinem Handy.',
      lead: 'Kein Konto. Kein Server. Keine Analytics-SDKs. TubeTrainer spricht mit YouTube nur, um die von dir gewählten Trainings-Videos zu finden und abzuspielen – und lädt oder speichert das Video selbst nie. Dein Trainingsverlauf gehört dir, und du kannst jederzeit ein versioniertes Backup exportieren.',
    },
    faq: {
      eyebrow: 'Fragen',
      title: 'Gut zu wissen.',
      items: [
        { q: 'Kostet es etwas?', a: 'V1 ist kostenlos. Kein Abo, keine Paywall, kein Konto.' },
        { q: 'Brauche ich ein YouTube-Konto oder einen API-Schlüssel?', a: 'Nein. Du kannst jeden YouTube-Link einfügen oder „Auf YouTube suchen“ ohne Einrichtung nutzen. Die In-App-Suche ist optional und nutzt deinen eigenen kostenlosen YouTube-API-Schlüssel, falls du einen hinzufügst.' },
        { q: 'Funktioniert es offline?', a: 'Der ganze Tracker funktioniert ohne Empfang. Nur das Abspielen eines Online-Videos braucht eine Verbindung – und wenn eine fehlschlägt, läuft das Loggen weiter.' },
        { q: 'Werden die Videos auf meinem Handy gespeichert?', a: 'Niemals. TubeTrainer speichert nur eine Referenz (Link, Titel, Vorschaubild) und spielt Videos über den regelkonformen YouTube-Player ab. Es lädt oder hostet nichts neu.' },
        { q: 'Kann ich meine Daten mitnehmen?', a: 'Ja – exportiere ein versioniertes JSON-Backup und importiere es, um wiederherzustellen oder das Gerät zu wechseln. Deine Bibliothek kommt mit.' },
        { q: 'Welche Geräte?', a: 'iPhone, iOS 18 und neuer. Dark- und Light-Theme inklusive.' },
      ],
    },
    download: {
      eyebrow: 'Hol dir die App',
      title: 'Sei einer der Ersten, die damit trainieren.',
      lead: 'TubeTrainer ist im App Store. Kostenlos, kein Konto – laden und loslegen.',
      sub: 'Laden im',
      note: 'Kostenlos · iPhone · iOS 18+',
    },
    footer: {
      tagline: 'Deine Trainer. Deine Übungen. Dein Fortschritt.',
      madeFor: '© 2026 TubeTrainer. Für alle, die es ernst meinen.',
      notAffiliated: 'Nicht mit YouTube oder Google verbunden.',
      privacy: 'Datenschutz', terms: 'Nutzungsbedingungen', support: 'Support',
    },
  },
};
