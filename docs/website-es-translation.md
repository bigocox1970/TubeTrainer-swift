# Website Spanish translation — for review

**STATUS: LIVE at https://tubetrainer.app/es/ since 2026-09-16.** ChatGPT's native review has been
applied and deployed. The **authoritative source is now `website/src/i18n/strings.js`** — this doc is
a historical review record, so the first-pass wording in the tables below may differ from what's live.

Corrections applied since first pass: Screens → **Pantallas**; FAQ → **Preguntas frecuentes**;
"tracker" kept as a loanword (hero + features); "un minuto de inicio" → **el punto de inicio**;
"ruedas de cien valores" → **interminables selectores de valores**; "La última vez está ahí mismo" →
**Tus datos de la última sesión están siempre a mano**; "biblioteca es portable" → **Puedes llevarte
tu biblioteca contigo**.

How to read: **EN** original, then **ES** first-pass, then a back-translation where a term was
debatable. Neutral Spanish aimed to read well in both Spain and Latin America.

---

## Navigation / chrome
| EN | ES |
|---|---|
| Coaching | Enseñanza |
| Training | Entrenamiento |
| Screens | Capturas |
| Privacy | Privacidad |
| FAQ | Preguntas |
| Download | Descargar |
| Skip to content | Saltar al contenido |

**← note:** "Coaching" — kept as **Enseñanza** (teaching). Alternative loanword **Coaching** is widely
understood in Spanish fitness. Tester: which reads more natural as a nav label?

## Hero
- **EN** Free · iPhone · No account → **ES** Gratis · iPhone · Sin cuenta
- **EN** The best coaching on YouTube, right beside your workout.
  **ES** La mejor enseñanza de YouTube, justo al lado de tu entrenamiento.
  _(back: "The best teaching from YouTube, right next to your workout.")_
- **EN** You already have coaches — they're on YouTube. TubeTrainer turns that scattered coaching into your **personal visual exercise manual**, wrapped around a seriously fast gym tracker.
  **ES** Ya tienes entrenadores: están en YouTube. TubeTrainer convierte esa enseñanza dispersa en tu **manual visual de ejercicios**, integrado en un registro de entrenamiento muy rápido.
- **EN** See how it works → **ES** Mira cómo funciona
- **EN** Free · iPhone · iOS 18+ → **ES** Gratis · iPhone · iOS 18+

## Coaching section
- **EN** The difference → **ES** La diferencia
- **EN** Every exercise gets the coach who makes it click.
  **ES** Cada ejercicio tiene al entrenador que te lo hace entender.
- **EN** One creator for bench, another for squats, another for mobility. Attach the exact video — or the exact moment — to any exercise. No blank rectangles: exercises without a coach show a discovery panel that makes building your library feel like collecting, not configuring.
  **ES** Un creador para el press de banca, otro para las sentadillas, otro para la movilidad. Adjunta el vídeo exacto —o el momento exacto— a cualquier ejercicio. Sin rectángulos vacíos: los ejercicios sin entrenador muestran un panel de descubrimiento que hace que crear tu biblioteca se sienta como coleccionar, no como configurar.
- Ticks:
  - Search YouTube or paste any link — even a Short. → Busca en YouTube o pega cualquier enlace, incluso un Short.
  - Save a start time so you jump straight to the useful part. → Guarda un minuto de inicio para saltar directo a lo importante.
  - Prioritise the trainers you already trust with favourite coaches. → Prioriza a los entrenadores en los que ya confías marcándolos como favoritos.
  - Compliant embedded playback with a clear "Open in YouTube". → Reproducción integrada y conforme, con un claro "Abrir en YouTube".

## Logging section
- **EN** Frictionless in the gym → **ES** Sin fricción en el gimnasio
- **EN** Log a set in seconds. One hand. Every time.
  **ES** Registra una serie en segundos. Con una mano. Siempre.
  _("serie" = set — standard in Spanish lifting.)_
- **EN** Big thumb-friendly controls, values pre-filled from last time, and a rest timer that starts itself. Watching the coach is always one tap away and never gets in the way of logging.
  **ES** Controles grandes pensados para el pulgar, valores rellenados desde la última vez y un temporizador de descanso que se inicia solo. Ver al entrenador está siempre a un toque y nunca estorba al registrar.
- Ticks:
  - **Last time** is right there — no screen hopping. → La **última vez** está ahí mismo, sin saltar de pantalla.
  - Tap to type or nudge with +/– . No hundred-value pickers. → Toca para escribir o ajusta con +/–. Sin ruedas de cien valores.
  - Complete a set → haptic → rest timer → next. → Completa una serie → vibración → descanso → siguiente.
  - Finish to a summary that celebrates real PRs. → Termina con un resumen que celebra tus récords reales (PR).

## Screens gallery
- **EN** A look inside → **ES** Un vistazo por dentro
- **EN** Deliberately designed, top to bottom. → **ES** Diseñado con cuidado, de arriba abajo.
- **EN** Dark-first, with a proper light mode. Every screen earns its place. → **ES** Modo oscuro por defecto, con un modo claro de verdad. Cada pantalla se gana su sitio.
- **EN** Swipe, scroll, or use the arrows → → **ES** Desliza, arrastra o usa las flechas →

## Feature grid
- **EN** Everything a serious log needs → **ES** Todo lo que necesita un registro serio
- **EN** A full-blooded tracker that happens to be free. → **ES** Un registro completo que, además, es gratis.

| Feature (EN) | Feature (ES) |
|---|---|
| **A real exercise catalog** — 50+ built-in movements across every muscle group, plus custom exercises. Forgiving search — type "RDL" and get Romanian Deadlift. | **Un catálogo de ejercicios de verdad** — más de 50 movimientos integrados para cada grupo muscular, y ejercicios personalizados. Búsqueda flexible: escribe "RDL" y aparece el Peso Muerto Rumano. |
| **History & personal records** — Every session saved. See last time before every set, track progression, and get honest PRs — heaviest set, estimated 1RM, best volume. | **Historial y récords personales** — Cada sesión guardada. Consulta la última vez antes de cada serie, sigue tu progresión y obtén PR honestos: serie más pesada, 1RM estimado, mejor volumen. |
| **Rest timer that just works** — Auto-starts on a completed set, counts down in the background, and notifies you when it's time — even with the app closed. | **Un temporizador de descanso que funciona** — Se inicia solo al completar una serie, cuenta atrás en segundo plano y te avisa cuando toca, incluso con la app cerrada. |
| **Works when the gym doesn't** — Terrible signal? Logging never blocks. If a video can't load you still see last time, log sets, and finish — fully offline. | **Funciona aunque el gimnasio no** — ¿Mala cobertura? Registrar nunca se bloquea. Si un vídeo no carga, sigues viendo la última vez, registras series y terminas, totalmente sin conexión. |
| **Yours, on your device** — No account, no server, no analytics. Everything is local. Export a versioned backup whenever you like and restore it anywhere. | **Tuyo, en tu dispositivo** — Sin cuenta, sin servidor, sin analíticas. Todo es local. Exporta una copia de seguridad con versiones cuando quieras y restáurala donde sea. |
| **Built to feel physical** — Deliberate haptics, short natural animation, Dynamic Type and full dark & light themes. Fast where it counts. | **Diseñado para sentirse físico** — Vibraciones cuidadas, animación breve y natural, Dynamic Type y modos oscuro y claro completos. Rápido donde importa. |

## Share flow
- **EN** Share → TubeTrainer → **ES** Compartir → TubeTrainer
- **EN** Found a great video? Save it without leaving YouTube. → **ES** ¿Has encontrado un buen vídeo? Guárdalo sin salir de YouTube.
- Step 1 — **Tap Share in YouTube** / On any video or Short, TubeTrainer shows up in the share sheet like any other app.
  → **Toca Compartir en YouTube** / En cualquier vídeo o Short, TubeTrainer aparece en el menú de compartir como una app más.
- Step 2 — **Pick the exercise** / Search your library right there and choose where it belongs.
  → **Elige el ejercicio** / Busca en tu biblioteca ahí mismo y elige a dónde va.
- Step 3 — **It's your coach** / The video is waiting on that exercise next time you train. Done.
  → **Ya es tu entrenador** / El vídeo te espera en ese ejercicio la próxima vez que entrenes. Listo.

## Privacy
- **EN** Privacy by default → **ES** Privacidad por defecto
- **EN** Your training stays on your phone. → **ES** Tu entrenamiento se queda en tu teléfono.
- **EN** No account. No server. No analytics SDKs. TubeTrainer talks to YouTube only to find and play the coaching you choose — and never downloads or stores the video itself. Your workout history is yours, and you can export a versioned backup any time.
  **ES** Sin cuenta. Sin servidor. Sin SDK de analíticas. TubeTrainer se conecta a YouTube solo para encontrar y reproducir la enseñanza que elijas, y nunca descarga ni almacena el vídeo. Tu historial de entrenamiento es tuyo, y puedes exportar una copia de seguridad con versiones cuando quieras.

## FAQ
| EN Q / A | ES Q / A |
|---|---|
| Does it cost anything? / V1 is free. No subscription, no paywall, no account. | ¿Cuesta algo? / La V1 es gratis. Sin suscripción, sin muro de pago, sin cuenta. |
| Do I need a YouTube account or API key? / No. You can paste any YouTube link or use "Search on YouTube" with zero setup. In-app search is optional and uses your own free YouTube API key if you add one. | ¿Necesito una cuenta de YouTube o una clave API? / No. Puedes pegar cualquier enlace de YouTube o usar "Buscar en YouTube" sin configurar nada. La búsqueda dentro de la app es opcional y usa tu propia clave API gratuita de YouTube si añades una. |
| Does it work offline? / The whole tracker works with no signal. Only playing an online video needs a connection — and if one fails, logging keeps working. | ¿Funciona sin conexión? / Todo el registro funciona sin señal. Solo reproducir un vídeo online necesita conexión, y si falla, el registro sigue funcionando. |
| Are the videos stored on my phone? / Never. TubeTrainer saves only a reference (link, title, thumbnail) and plays videos through YouTube's compliant player. It doesn't download or rehost anything. | ¿Se guardan los vídeos en mi teléfono? / Nunca. TubeTrainer guarda solo una referencia (enlace, título, miniatura) y reproduce los vídeos con el reproductor oficial de YouTube. No descarga ni realoja nada. |
| Can I move my data? / Yes — export a versioned JSON backup and import it to restore or move devices. Your library is portable. | ¿Puedo mover mis datos? / Sí: exporta una copia JSON con versiones e impórtala para restaurar o cambiar de dispositivo. Tu biblioteca es portable. |
| Which devices? / iPhone, iOS 18 and later. Dark and light themes included. | ¿Qué dispositivos? / iPhone, iOS 18 o posterior. Con modos oscuro y claro. |

## Download CTA
- **EN** Get the app → **ES** Consigue la app
- **EN** Be one of the first to train with it. → **ES** Sé de los primeros en entrenar con ella.
- **EN** TubeTrainer is on the App Store. Free, no account — download and start training.
  **ES** TubeTrainer ya está en la App Store. Gratis, sin cuenta: descárgala y empieza a entrenar.
- **EN** Free · iPhone · iOS 18+ → **ES** Gratis · iPhone · iOS 18+
- Footer: © 2026 TubeTrainer. Made for lifters. → © 2026 TubeTrainer. Hecho para quienes levantan.
- Not affiliated with YouTube or Google. → Sin afiliación con YouTube ni Google.

---

## Terms the testers should specifically confirm
1. **Coaching / Enseñanza vs Coaching** (nav + hero) — which reads best to a Spanish lifter?
2. **serie** for "set", **repeticiones/reps** — confirm regional preference.
3. **press de banca / sentadillas / peso muerto rumano** — standard, but confirm.
4. **registro de entrenamiento** for "tracker/log" vs "app de gimnasio".
5. **Tú (informal)** used throughout — correct register for fitness; confirm not too casual.
6. App Store metadata (title/subtitle/keywords) will be translated separately for ASO — testers'
   keyword instincts (what they'd *search*) are gold here.
