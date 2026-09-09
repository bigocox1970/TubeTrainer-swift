# TubeTrainer iOS --- Product Requirements Document

**Product:** TubeTrainer\
**Domain:** TubeTrainer.app\
**Platform:** iPhone / native iOS\
**Implementation:** Swift + SwiftUI\
**Persistence:** SwiftData / local-first\
**V1 price:** Free\
**Accounts:** None\
**Backend:** None\
**Cloud database:** None\
**Status:** Build specification for Claude Code / Cursor

> **PRODUCT RULE:** TubeTrainer is not a workout tracker with YouTube
> bolted onto it. It is a personal coaching library that happens to be
> an excellent workout tracker.

------------------------------------------------------------------------

## 0. CLAUDE CODE EXECUTION DIRECTIVE

You are building a production-quality native iOS application called
**TubeTrainer**.

Do not stop at: - a prototype, - a wireframe, - a collection of
placeholder screens, - mocked navigation, - TODO comments, - fake
buttons, - hard-coded demo state that prevents normal use, - or a
project that merely compiles.

Work through the entire V1 specification. Build, run, inspect, fix
compiler/runtime issues, test the principal flows, improve obvious UX
defects, and continue until the app is genuinely usable.

When a requirement is technically impossible because of an external
platform restriction, do **not** silently fake it. Implement the best
compliant fallback and document the limitation clearly in the
code/README.

Prioritize in this order:

1.  Reliability
2.  Frictionless gym use
3.  Visual quality
4.  Correct persistence
5.  YouTube integration
6.  Feature breadth

The application must feel deliberately designed. A functional but ugly
implementation is a failed implementation.

------------------------------------------------------------------------

# 1. PRODUCT VISION

People already have fitness coaches.

They are on YouTube.

A user may trust one creator for bench press, another for lateral
raises, another for squats and another for mobility.

The problem is that the best coaching gets lost among subscriptions,
history, playlists, Shorts and search results.

At the gym, the user should not need to remember:

> "What was that video where he explained exactly where my elbows should
> be?"

TubeTrainer turns those scattered pieces of coaching into the user's
**personal visual exercise manual**.

Every exercise can have:

1.  **My Coach** --- the user's chosen video or timestamped section.
2.  **My Workout** --- sets, reps, load, notes and rest.
3.  **My History** --- what the user previously achieved.

The user decides who teaches them.

TubeTrainer remembers.

------------------------------------------------------------------------

# 2. V1 GOALS

V1 must prove five things:

1.  Users enjoy attaching trusted coaching videos to exercises.
2.  The coaching video is useful while actually training.
3.  TubeTrainer can replace a conventional basic gym log.
4.  Building a personal coaching library is enjoyable rather than
    administrative.
5.  The UX is sufficiently polished that users voluntarily keep using
    it.

V1 deliberately avoids monetization complexity.

No StoreKit paywall. No subscription. No login. No account creation. No
server. No social network. No AI form scoring.

Those can come after real-world usage validates the core product.

------------------------------------------------------------------------

# 3. CORE PRODUCT LOOP

## Discovery loop

**Discover video → Save to TubeTrainer → Choose exercise → Set as
coach**

A user may discover coaching: - from TubeTrainer search/discovery, -
from one of their favorite coaches, - or externally and bring the
YouTube link into TubeTrainer.

## Gym loop

**Open → Start Workout → Exercise → Watch if needed → Log set → Rest →
Repeat → Next exercise**

The user must be able to complete common actions one-handed.

Logging a set must take seconds.

Watching the coaching video is optional during every set. It must be
immediately accessible without blocking logging.

------------------------------------------------------------------------

# 4. BRAND & VISUAL DIRECTION

The supplied TubeTrainer app icon is the visual anchor.

The product should feel:

-   premium,
-   dark,
-   physical,
-   confident,
-   fast,
-   modern,
-   cinematic without being theatrical.

Think of the discipline and polish associated with Apple's fitness
products combined with the immediacy of video and the speed of a serious
strength tracker.

Do not clone another product.

## Core palette

Use semantic design tokens rather than scattering literal colors
throughout views.

Suggested tokens: - `backgroundPrimary`: near-black -
`backgroundSecondary`: charcoal - `surface`: elevated dark gray -
`textPrimary`: warm/clean white - `textSecondary`: muted gray -
`brandRed`: vivid TubeTrainer red - `brandRedPressed`: darker red -
`success`: system semantic where appropriate - `separator`: subtle
low-contrast line

The app is **dark-first**.

Support light appearance sensibly, but do not compromise the identity of
the primary dark experience.

## UI rules

Avoid: - endless nested cards, - blue default buttons, - excessive
borders, - giant gradients, - bodybuilding flames/lightning, - tiny tap
targets, - skeuomorphic gym equipment, - dashboard clutter, -
spreadsheets disguised as interfaces.

Prefer: - generous spacing, - bold typography, - strong hierarchy, -
edge-to-edge imagery/video where useful, - restrained red accents, -
subtle material/elevation, - tactile controls, - excellent haptics, -
short purposeful animation.

Use SF Symbols where appropriate.

The interface should still look excellent with Dynamic Type.

------------------------------------------------------------------------

# 5. NAVIGATION

Use a simple bottom tab architecture.

Recommended tabs:

### Today

Home and quickest route into training.

### Library

Exercises and personal coaching library.

### History

Completed workouts, exercise progression and records.

### You

Preferences, coaches, data export/import and app information.

During an active workout, prioritize the workout session rather than
forcing the user through normal tab navigation.

------------------------------------------------------------------------

# 6. FIRST LAUNCH / ONBOARDING

The user must never finish onboarding staring at an empty application.

Onboarding creates **structure**, not fake coaching content.

Keep onboarding fast and skippable where possible.

## Screen 1 --- Brand

TubeTrainer icon / wordmark.

Headline:

**Your coaches. Your exercises. Your progress.**

Supporting copy:

Save the best exercise coaching you find on YouTube and keep it right
beside your workout.

Primary action:

**Build My Trainer**

Secondary:

**I'll set it up myself**

No account request.

## Screen 2 --- Training experience

Ask lightweight experience level:

-   New to training
-   Some experience
-   Experienced

This can influence default recommendations but must not lock features.

## Screen 3 --- Choose training structure

Options such as:

-   Full Body
-   Upper / Lower
-   Push / Pull / Legs
-   Body Part Split
-   Build My Own

Selecting a template creates editable workout plans immediately.

Do not imply that the template is medical or professional advice.

## Screen 4 --- Customize exercises

Show the exercises in the selected structure.

Allow: - add, - remove, - reorder, - search, - replace.

Seed with sensible common exercises.

## Screen 5 --- Favorite coaches (optional)

Explain:

**Already have trainers you trust?**

Allow the user to add/select favorite YouTube channels/coaches if
technically feasible through compliant YouTube mechanisms.

This step is optional.

Do not make users configure five creators before seeing the app.

## Screen 6 --- Coaching library explanation

Show an example exercise:

**Shoulder Press**

with a video area explaining:

**Find your Shoulder Press coach**

-   Recommended
-   My Coaches
-   Search

Explain that the user can change their chosen coaching video whenever
they like.

## Completion

Enter a fully populated workout structure.

Exercises without selected coaching videos should have polished coaching
discovery states, never blank rectangles.

------------------------------------------------------------------------

# 7. BUILT-IN EXERCISE CATALOG

Ship a useful local exercise catalog.

It must be broad enough that a normal gym user is unlikely to
immediately encounter missing basics.

Categories should include:

-   Chest
-   Back
-   Shoulders
-   Biceps
-   Triceps
-   Quadriceps
-   Hamstrings
-   Glutes
-   Calves
-   Core
-   Full Body
-   Cardio
-   Mobility / Warm-up

Include common equipment/movement variants such as:

-   Barbell Bench Press
-   Dumbbell Bench Press
-   Incline Dumbbell Press
-   Chest Press Machine
-   Cable Fly
-   Push-Up
-   Barbell Overhead Press
-   Dumbbell Shoulder Press
-   Machine Shoulder Press
-   Lateral Raise
-   Rear Delt Fly
-   Face Pull
-   Pull-Up
-   Lat Pulldown
-   Barbell Row
-   Dumbbell Row
-   Seated Cable Row
-   Chest-Supported Row
-   Deadlift
-   Romanian Deadlift
-   Back Squat
-   Front Squat
-   Leg Press
-   Hack Squat
-   Leg Extension
-   Leg Curl
-   Hip Thrust
-   Walking Lunge
-   Bulgarian Split Squat
-   Standing Calf Raise
-   Seated Calf Raise
-   Barbell Curl
-   Dumbbell Curl
-   Hammer Curl
-   Cable Curl
-   Triceps Pushdown
-   Overhead Triceps Extension
-   Skull Crusher
-   Dip
-   Plank
-   Hanging Leg Raise
-   Cable Crunch
-   Ab Wheel

The catalog should be data-driven so additional exercises can be added
easily.

Allow users to create custom exercises.

Each exercise should support: - name, - category, - equipment, -
optional aliases/search terms, - coaching video reference, - notes, -
workout history.

------------------------------------------------------------------------

# 8. TODAY SCREEN

This is the app's front door.

It should not resemble an analytics dashboard.

Primary content:

### Greeting/context

Keep restrained. Do not waste vertical space.

### Next workout

Large hero treatment.

Example:

**PUSH DAY**

6 exercises\
Last trained Monday

Primary button:

**START WORKOUT**

### Continue workout

If an unfinished session exists, this takes priority.

### Recent / suggested

Optional compact section showing recent exercises or coaching additions.

The user should be able to open TubeTrainer and begin training within
approximately two taps.

------------------------------------------------------------------------

# 9. WORKOUT PLAN SCREEN

Show: - workout name, - exercises in order, - most recent performance, -
coaching status.

Example:

**Push Day**

1.  Barbell Bench Press\
    Coach: Jeff --- 0:42\
    Last: 80 × 8

2.  Incline Dumbbell Press\
    Find your coach\
    Last: 30 × 10

3.  Shoulder Press\
    Coach attached\
    Last: 32 × 9

Allow: - reorder, - add exercise, - remove, - edit target sets/reps, -
rename workout.

Primary action remains **Start Workout**.

------------------------------------------------------------------------

# 10. ACTIVE WORKOUT --- MOST IMPORTANT SCREEN

This screen receives disproportionate design attention.

A user may spend most of their TubeTrainer time here.

## Header

Show: - workout name, - elapsed workout time, - unobtrusive finish
control.

## Exercise identity

Large exercise title.

Example:

**Dumbbell Shoulder Press**

Optional small category/equipment line.

## Coaching area

If a coaching video exists:

Display a beautiful video preview/player area near the top.

Show: - thumbnail/player, - coach/channel name when available, -
title, - selected clip/time marker if relevant, - open/watch action.

The coaching media must feel like part of the exercise rather than an
external attachment.

Provide a clear route to open the original content in YouTube.

Do not download, rip, mirror or locally redistribute YouTube video
content.

Respect YouTube platform/API/player requirements.

If inline playback cannot be implemented compliantly/reliably for a
particular content type, use the best compliant embedded/web/player
experience and preserve a prominent **Open in YouTube** fallback.

## No coaching video

Never show empty space.

Show an attractive media-shaped discovery panel:

**Find your Shoulder Press coach**

Supporting copy:

Save the explanation that makes this exercise click for you.

Actions:

**Recommended**\
**My Coaches**\
**Search**

This panel should make an incomplete coaching library feel exciting to
complete.

## Last workout

Directly before/alongside set logging, show the relevant previous
performance.

Example:

**LAST TIME**

32.5 × 10\
32.5 × 9\
30 × 11

Do not bury this behind another screen.

## Set logger

Large, thumb-friendly controls.

Columns/fields: - Set - Previous - Weight - Reps - Complete

Prefill sensible values from previous set/session.

Example:

`1 | 32.5 × 10 | [32.5 kg] | [10 reps] | ✓`

The user must be able to alter weight/reps rapidly.

Consider: - tap value then numeric keypad, - +/- convenience controls, -
previous-value quick fill.

Do not make users navigate through pickers containing hundreds of
values.

On complete: - persist set immediately, - haptic confirmation, -
visually mark complete, - start rest timer if enabled.

## Notes

Exercise note access should be quick but visually secondary.

Useful for: - seat position, - grip, - cues, - pain-free modification, -
machine setting.

Example:

> Seat 4. Keep elbows slightly forward.

## Exercise navigation

Large next/previous controls or an excellent swipe interaction.

Avoid accidental navigation while editing values.

------------------------------------------------------------------------

# 11. REST TIMER

Rest timing must be effortless.

Default can be configured globally and overridden per exercise.

Suggested presets: - 60 sec - 90 sec - 2 min - 3 min

When a set completes: - timer starts automatically if enabled, - compact
persistent timer appears, - user can +15 sec / skip, -
haptic/notification when complete.

Support background timing correctly.

Do not require the app to remain foregrounded.

------------------------------------------------------------------------

# 12. COACHING DISCOVERY

This is TubeTrainer's defining differentiator.

For any exercise, the user should have three primary discovery routes.

## Recommended

Generate a sensible search intent from the exercise.

Examples:

`dumbbell shoulder press proper form`

`dumbbell shoulder press form shorts`

`bench press technique`

Favor concise instructional content/Shorts where possible.

Do not claim search ranking guarantees that the YouTube APIs do not
provide.

The implementation must remain adaptable if YouTube search/API
capabilities or quota requirements constrain the exact experience.

## My Coaches

Search/browse content from channels the user has identified as
favorites.

The user's preferred creators should receive priority when finding
coaching for an exercise.

## Search

Free YouTube-oriented search.

Prepopulate the exercise name where helpful.

------------------------------------------------------------------------

# 13. SELECTING A COACHING VIDEO

When a user selects content:

Show a preview and ask:

**Use this for Dumbbell Shoulder Press?**

Actions: - Set as My Coach - Choose another

Store metadata/reference needed to return to the content.

Do not store the actual copyrighted video.

Where supported for standard videos, allow the user to save a **start
time** so a useful segment of a longer video can be revisited quickly.

Optional UI:

**Start coaching at:** 02:14

If reliable end-time clipping is not supported by the chosen compliant
player implementation, do not pretend that it is. A saved start position
alone is valuable.

For Shorts, store the canonical YouTube reference and display
appropriately.

------------------------------------------------------------------------

# 14. EXTERNAL YOUTUBE DISCOVERY / SHARE FLOW

Investigate and implement the most reliable Apple/YouTube-compliant way
to bring a YouTube URL into TubeTrainer.

Ideal user experience:

User finds a great YouTube video/Short outside TubeTrainer.

They choose TubeTrainer through an available share/import mechanism.

TubeTrainer receives/parses the URL.

Then displays:

**Save to an exercise**

Search/select: - Shoulder Press - Lateral Raise - etc.

Then:

**Set as My Coach**

If an iOS Share Extension is appropriate and robust, implement it.

If app-group/shared-container configuration is required, implement
correctly.

If the chosen integration introduces unacceptable fragility for V1,
provide an excellent paste-link flow and document why.

Never implement video downloading.

------------------------------------------------------------------------

# 15. FAVORITE COACHES

Provide a **My Coaches** area.

Each coach/channel entry can show: - avatar if available, - channel
name, - number of exercises for which they are the selected coach.

The user can: - add coach, - remove favorite, - browse/search their
content, - see which exercises use them.

Do not require favorite coaches.

A user with zero favorite coaches must have a complete experience
through Recommended and Search.

------------------------------------------------------------------------

# 16. LIBRARY

Library should feel closer to a personal collection than a spreadsheet.

Top: **My Exercises**

Search field.

Useful filters: - All - Has Coach - Needs Coach - recently used - body
category

Each row/card should communicate: - exercise, - body category, -
coaching status, - recent performance.

Tapping opens the exercise detail.

A **Needs Coach** filter is particularly important because it turns
filling the coaching library into a satisfying collection-building
activity.

Optional progress indicator:

**Your coaching library: 18 / 31 exercises**

Do not make this guilt-inducing.

------------------------------------------------------------------------

# 17. EXERCISE DETAIL

Exercise detail combines three concepts elegantly:

## COACH

Chosen video.

Change Coach.

Browse alternatives.

Open original.

## TRAIN

Recent set performance and shortcut to start/log exercise where context
permits.

## HISTORY

Recent sessions and progression.

Also: - notes, - personal bests, - custom settings, - rest duration.

------------------------------------------------------------------------

# 18. WORKOUT COMPLETION

Finishing should feel rewarding without becoming childish.

Summary:

**Push Day Complete**

Duration: 54 min\
18 working sets\
Volume: appropriate calculated total where meaningful\
PRs: 2

Highlight genuine improvements.

Examples: - Heaviest bench set - Rep PR at 80 kg - Total volume
improvement

Use a restrained animation/haptic.

Primary action:

**DONE**

No mandatory social sharing.

------------------------------------------------------------------------

# 19. HISTORY

Provide two useful history views.

## Workout history

Chronological sessions: - date, - workout, - duration, - exercises, -
volume where applicable.

## Exercise history

For an individual exercise: - date, - sets, - weight, - reps, -
estimated performance trends.

A simple progression chart may be used where meaningful.

Do not turn V1 into a sports-science analytics suite.

------------------------------------------------------------------------

# 20. PERSONAL RECORDS

Recognize useful milestones locally.

Possible records: - heaviest completed set, - highest reps at a given
weight, - estimated 1RM, - session volume.

If using estimated 1RM, choose one documented formula consistently and
label the result as estimated.

Do not imply medical or physiological precision.

------------------------------------------------------------------------

# 21. DATA MODEL

Use SwiftData cleanly.

Suggested conceptual entities:

### Exercise

-   id UUID
-   name
-   normalizedName
-   category
-   equipment
-   isCustom
-   notes
-   defaultRestSeconds
-   createdAt

### CoachingSource

-   id UUID
-   exercise relationship
-   provider (`youtube`)
-   canonicalURL
-   videoID where available
-   contentType
-   title
-   channelName
-   channelID where available
-   thumbnailURL where allowed
-   startSeconds optional
-   isPrimary
-   createdAt
-   updatedAt

Allow architecture for multiple saved coaching sources per exercise even
if V1 emphasizes one primary **My Coach** selection.

### Coach

-   id UUID
-   provider
-   channelID
-   name
-   channelURL
-   avatar reference if appropriate
-   isFavorite

### WorkoutTemplate

-   id UUID
-   name
-   ordering
-   createdAt

### WorkoutTemplateExercise

-   id UUID
-   workout relationship
-   exercise relationship
-   order
-   targetSets optional
-   targetRepMin optional
-   targetRepMax optional

### WorkoutSession

-   id UUID
-   workoutTemplateID optional
-   nameSnapshot
-   startedAt
-   completedAt optional
-   notes

### ExerciseSession

-   id UUID
-   workoutSession relationship
-   exercise relationship
-   order
-   notesSnapshot

### WorkoutSet

-   id UUID
-   exerciseSession relationship
-   setNumber
-   weight
-   reps
-   setType
-   completedAt

Use snapshots where appropriate so historical records do not become
nonsensical after users rename templates.

------------------------------------------------------------------------

# 22. UNITS

Support: - kg - lb

Choose sensible locale-based initial suggestion, but let the user change
it.

Persist preference locally.

Do not silently convert historical entered values in a way that causes
rounding surprises.

------------------------------------------------------------------------

# 23. LOCAL-FIRST DATA

Everything required for normal TubeTrainer usage must live locally.

No user account.

No remote app database.

No developer-controlled backend dependency for workout history.

Network connectivity is required only for features that inherently
require it, such as finding/watching online YouTube content.

The workout tracker itself must continue to work offline.

Cached metadata should degrade gracefully.

------------------------------------------------------------------------

# 24. EXPORT / BACKUP

Users may build a valuable coaching library and years of training
history.

Provide local data export.

Recommended: - versioned JSON backup containing user-created app data
and external video references/metadata, - system share sheet, -
import/restore.

Never export downloaded YouTube media because TubeTrainer must not
download it in the first place.

Import must: - validate schema/version, - fail safely, - avoid
corrupting existing data, - provide a clear confirmation before
destructive replacement/merge behavior.

Design the backup format for future migration.

------------------------------------------------------------------------

# 25. YOUTUBE INTEGRATION --- IMPORTANT ENGINEERING RULES

Before implementation, verify the **current** official YouTube/Google
requirements rather than relying on old assumptions.

The app should use official/compliant mechanisms for: - search where
available, - metadata, - thumbnails, - channel references, - embedded
playback, - opening content in YouTube/browser.

Potential implementation may involve YouTube Data API access and
official/allowed player mechanisms.

Keep YouTube integration behind a service/protocol boundary so it can be
changed without rewriting workout UI.

For example:

`VideoDiscoveryService`

with methods conceptually equivalent to: - searchVideos(query) -
searchShortForm(query) - videosForCoach(...) - resolveVideo(url) -
metadata(videoID)

Do not couple views directly to network code.

### API key handling

A mobile application cannot truly keep a static API secret secret.

If a YouTube API key is required for V1: - use appropriate Google
restrictions, - restrict API scope, - avoid treating obfuscation as
security, - document quota implications.

Do not introduce a backend merely to satisfy architectural fashion. V1's
goal remains backend-free unless a hard external requirement makes that
impossible.

### Platform compliance

Do not: - download YouTube videos, - strip attribution, - suppress
required player controls/branding, - imply ownership, - circumvent
ads, - bypass YouTube restrictions.

Provide **Open in YouTube** prominently where useful.

------------------------------------------------------------------------

# 26. NETWORK FAILURE

The gym may have terrible reception.

TubeTrainer must handle this gracefully.

If the selected coaching video cannot load:

Keep the entire workout logger usable.

Display something like:

**Video unavailable right now**

with: - Retry - Open in YouTube

Never allow failed media to block the workout.

------------------------------------------------------------------------

# 27. SEARCH EXPERIENCE

Exercise search must be extremely forgiving.

Support: - partial names, - aliases, - category, - equipment.

Examples:

`shoulder press` should find machine/dumbbell/barbell overhead press
variants.

`RDL` should find Romanian Deadlift.

Custom exercises should participate equally.

------------------------------------------------------------------------

# 28. HAPTICS

Use haptics intentionally.

Examples: - set completed, - rest finished, - workout completed, -
reorder snap, - primary coach selected.

Do not vibrate on every tap.

------------------------------------------------------------------------

# 29. ANIMATION

Animation should make the app feel physical and responsive.

Examples: - set completion state, - video panel expansion, - exercise
transitions, - rest timer completion, - workout completion.

Prefer short spring/natural animations.

Respect Reduce Motion.

No decorative animation should delay logging.

------------------------------------------------------------------------

# 30. ACCESSIBILITY

Implement: - Dynamic Type, - VoiceOver labels, - sufficient contrast, -
minimum sensible tap targets, - Reduce Motion behavior, - controls that
do not rely solely on color.

Gym usage makes accessibility improvements useful even for users without
permanent accessibility requirements.

------------------------------------------------------------------------

# 31. NOTIFICATIONS

Only use notifications for useful time-sensitive behavior such as a rest
timer completing while TubeTrainer is backgrounded.

Request permission in context rather than immediately on first launch.

Do not ask for notifications during onboarding without explaining why.

------------------------------------------------------------------------

# 32. PRIVACY

V1 should have an exceptionally simple privacy story.

Workout information stays on the user's device unless they explicitly
export it.

TubeTrainer accesses YouTube/network services only to provide
video-related functionality.

Do not add third-party analytics/advertising SDKs merely because they
are common.

If diagnostics are added, favor privacy-preserving Apple-native
mechanisms.

------------------------------------------------------------------------

# 33. SETTINGS / YOU

Keep settings compact.

Include:

### Training

-   kg/lb
-   default rest timer
-   auto-start rest timer

### Coaching

-   My Coaches
-   YouTube-related preferences where required

### Data

-   Export Backup
-   Import Backup

### Appearance

-   System
-   Dark
-   Light

### About

-   TubeTrainer
-   version/build
-   TubeTrainer.app
-   privacy
-   acknowledgements as required

Do not build a settings labyrinth.

------------------------------------------------------------------------

# 34. ARCHITECTURE

Use maintainable native architecture without enterprise overengineering.

Recommended: - SwiftUI - SwiftData - Observation / modern state
patterns - async/await - URLSession - protocol-backed services -
dependency injection sufficient for testing

Suggested modules/groups:

    TubeTrainer/
      App/
      Models/
      Persistence/
      Features/
        Onboarding/
        Today/
        Workouts/
        ActiveWorkout/
        ExerciseLibrary/
        Coaching/
        History/
        Settings/
      Services/
        VideoDiscovery/
        VideoPlayback/
        Backup/
        Notifications/
      DesignSystem/
      Resources/
      Utilities/

Avoid a single gigantic view model.

Avoid unnecessary third-party dependencies.

Prefer Apple frameworks unless a dependency provides substantial value.

------------------------------------------------------------------------

# 35. DESIGN SYSTEM

Create reusable primitives rather than styling each screen
independently.

Examples:

-   `TTPrimaryButton`
-   `TTSecondaryButton`
-   `TTIconButton`
-   `TTVideoHero`
-   `TTExerciseRow`
-   `TTSetRow`
-   `TTSectionHeader`
-   `TTEmptyCoachView`
-   `TTRestTimer`
-   `TTBadge`
-   `TTSearchField`

Create: - spacing scale, - radius scale, - typography tokens, - semantic
colors, - animation durations, - haptic helpers.

This is how TubeTrainer remains visually coherent.

------------------------------------------------------------------------

# 36. APP ICON / BRAND ASSETS

Use the approved TubeTrainer icon supplied with the project.

Do not redraw it casually.

Ensure AppIcon asset catalog requirements are satisfied correctly for
the target SDK.

The icon's red/black/white identity should influence the product without
making every screen look like the icon.

Do not place the full icon unnecessarily throughout the app.

------------------------------------------------------------------------

# 37. SAMPLE DATA

For development/debug builds, provide optional sample data to rapidly
inspect all UI states.

Sample data may include: - Push Day - Pull Day - Legs - representative
workout history - representative coaching metadata

Production first launch must follow actual onboarding and must not
pretend the user completed workouts they did not perform.

------------------------------------------------------------------------

# 38. ERROR STATES

Design real error states for:

-   offline YouTube search,
-   invalid pasted YouTube URL,
-   unavailable/deleted video,
-   quota/API failure,
-   import failure,
-   corrupt backup,
-   notification denial.

Errors must be human-readable.

Never display raw HTTP errors to users.

------------------------------------------------------------------------

# 39. EMPTY STATES

Empty states are product moments.

Examples:

### Exercise has no coach

**Find your Bench Press coach**

The best explanation is the one that works for you.

[Recommended](#recommended) [My Coaches](#my-coaches) [Search](#search)

### No favorite coaches

**Who do you learn from?**

Add the YouTube trainers you already trust --- or skip this and discover
videos exercise by exercise.

### No workout history

**Your first session starts here.**

\[Start Workout\]

No generic: `No data.`

------------------------------------------------------------------------

# 40. FUTURE --- TUBETRAINER PRO

Do **not** implement a paywall in V1.

However, avoid architecture that prevents these future capabilities.

Potential TubeTrainer Pro features:

### Form Check

Record the user performing an exercise.

Use Apple's Vision/body-pose capabilities where appropriate.

Potential metrics: - joint paths, - range of motion, - left/right
symmetry, - tempo, - repeat consistency.

Future implementations may compare measurable pose/movement
characteristics against coaching/reference criteria.

Do not promise that arbitrary 2D YouTube footage can provide clinically
accurate biomechanical comparison.

### Official Coach Packs

This is a major future commercial opportunity.

TubeTrainer partners with fitness creators.

Creator produces a structured library:

**Coach X --- TubeTrainer Pack**

Covering: - Bench Press - Shoulder Press - Squat - Deadlift - Lateral
Raise - etc.

A user could add the creator's entire coaching library rapidly.

Future commercial model could include: - TubeTrainer Pro subscription, -
creator revenue share, - creator referral codes/links, - exclusive
coaching collections.

This must remain a future hook, not V1 complexity.

### Sync

Possible future: - iCloud/CloudKit, - device sync, - account
portability.

Local model IDs and backup schema should make migration feasible.

### Advanced training

Possible future: - supersets, - drop sets, - RPE/RIR, - plate
calculator, - warm-up calculation, - richer progression analytics, -
Apple Watch companion, - Live Activities.

Do not build them unless they are trivial and do not delay V1.

------------------------------------------------------------------------

# 41. FEATURES EXPLICITLY OUT OF SCOPE FOR V1

Do not build:

-   AI form analysis
-   paid subscription
-   StoreKit products
-   TubeTrainer account system
-   TubeTrainer backend
-   social feed
-   messaging
-   creator marketplace
-   meal tracking
-   calorie tracking
-   bodyweight/health analytics platform
-   Apple Watch app
-   web application
-   Android app
-   video downloading
-   video hosting
-   public profiles

V1 wins through focus.

------------------------------------------------------------------------

# 42. KEY UX ACCEPTANCE TESTS

The following scenarios must work cleanly.

## Scenario A --- brand-new user

1.  Install.
2.  Open.
3.  Understand TubeTrainer within seconds.
4.  Select Push/Pull/Legs.
5.  Customize exercises.
6.  Skip favorite coaches.
7.  Arrive at a useful Today screen.
8.  Start Push workout.
9.  See Bench Press with a polished **Find your coach** state.
10. Log workout without needing YouTube at all.

PASS: app is useful before coaching library is populated.

## Scenario B --- find coaching

1.  Open Shoulder Press.
2.  Tap Recommended.
3.  Discover relevant YouTube coaching.
4.  Select a video.
5.  Set it as My Coach.
6.  Return to Shoulder Press.
7.  Video is now prominently associated with exercise.

PASS: this feels like saving something to a personal collection, not
configuring a URL field.

## Scenario C --- gym session

1.  Open app.
2.  Start workout.
3.  View previous Bench Press result.
4.  Optionally watch coach.
5.  Enter weight/reps.
6.  Complete set.
7.  Rest timer begins.
8.  Complete remaining sets.
9.  Move to next exercise.
10. Finish workout.
11. See useful summary.

PASS: no unnecessary screen hopping.

## Scenario D --- offline/poor signal

1.  Begin workout.
2.  Video fails.
3.  App explains media is unavailable.
4.  Previous workout data remains visible.
5.  Set logging remains fully functional.
6.  Workout completes and persists.

PASS: TubeTrainer remains a gym tracker without internet.

## Scenario E --- backup

1.  User has custom workouts/history/coaching references.
2.  Export backup.
3.  Import through supported restore flow.
4.  Data reconstructs correctly.

PASS: user-created library is portable.

------------------------------------------------------------------------

# 43. PERFORMANCE

The app should feel instantaneous for local operations.

Targets: - fast cold launch, - immediate navigation, - no visible
database stalls, - smooth scrolling, - thumbnail loading that never
blocks UI, - asynchronous network operations, - sensible image caching.

Never block the main actor with network requests or expensive parsing.

------------------------------------------------------------------------

# 44. TESTING

Add meaningful tests.

At minimum test: - workout persistence, - set logging, -
previous-session lookup, - workout completion, - unit preference
behavior, - backup encode/decode, - invalid backup handling, - YouTube
URL parsing, - coaching-source persistence, - exercise search aliases.

Add UI tests for the principal happy path if practical.

------------------------------------------------------------------------

# 45. QUALITY GATE

Before declaring the implementation complete:

### Build

-   clean build succeeds
-   no compiler errors
-   eliminate avoidable warnings

### Launch

-   fresh install works
-   onboarding works
-   relaunch persistence works

### Workouts

-   templates persist
-   active workout survives expected lifecycle events
-   sets persist
-   previous values appear correctly
-   rest timer behaves correctly

### Coaching

-   search/discovery behaves as implemented
-   selected coaching source persists
-   invalid links fail gracefully
-   open-in-YouTube fallback works
-   offline state does not break workout

### Visual

Inspect every primary screen.

Ask: - Is hierarchy obvious? - Are tap targets large enough? - Is
anything using accidental default SwiftUI styling? - Does the screen
look intentionally TubeTrainer? - Is there unnecessary text? - Is there
unnecessary chrome? - Can the primary action be found instantly?

If not, improve it.

------------------------------------------------------------------------

# 46. THE "NO CLAUDE CRUD APP" RULE

This requirement is explicit.

Do not produce:

-   NavigationStack
-   Form
-   List
-   default blue buttons
-   gray rectangles
-   and call the application finished.

SwiftUI defaults are implementation primitives, not the TubeTrainer
visual identity.

Custom styling must remain maintainable and accessible, but TubeTrainer
needs a recognizable design.

The active workout screen and coaching discovery experience deserve the
highest visual effort.

------------------------------------------------------------------------

# 47. PRODUCT COPY STYLE

Copy should be: - short, - confident, - friendly, - non-preachy.

Use:

**Find your Shoulder Press coach**

rather than:

**No instructional media has been selected for this exercise.**

Use:

**Last time**

rather than:

**Previous exercise performance**

Use:

**Start Workout**

rather than:

**Initiate Training Session**

TubeTrainer should sound like somebody who actually goes to the gym.

------------------------------------------------------------------------

# 48. FIRST BUILD ORDER

Implement in this sequence unless the existing project state gives a
compelling technical reason otherwise.

### Phase 1 --- Foundation

-   project
-   app theme/design system
-   SwiftData models
-   exercise seed catalog
-   persistence
-   navigation

### Phase 2 --- Onboarding

-   training structure
-   exercise customization
-   optional coaches
-   populated first-run state

### Phase 3 --- Workout engine

-   templates
-   active session
-   set logging
-   previous performance
-   rest timer
-   completion
-   history

This must be solid before chasing media complexity.

### Phase 4 --- Coaching

-   coaching source model
-   URL parsing
-   YouTube service boundary
-   search/discovery
-   recommended search
-   favorite coaches
-   video/player experience
-   open-in-YouTube fallback

### Phase 5 --- Library

-   exercise browsing
-   coaching completion state
-   exercise detail
-   coach management

### Phase 6 --- Data safety

-   export
-   import
-   validation

### Phase 7 --- Polish

-   haptics
-   animation
-   accessibility
-   error states
-   offline states
-   performance
-   visual inspection

### Phase 8 --- Verification

-   tests
-   clean build
-   fresh install test
-   full workout test
-   full coaching assignment test
-   backup round trip

------------------------------------------------------------------------

# 49. DEFINITION OF DONE

TubeTrainer V1 is done when a real person can:

1.  download it,
2.  create their training structure without registering,
3.  begin training immediately,
4.  find or attach YouTube coaching to their exercises,
5.  gradually build their own coaching library,
6.  watch/access their selected coaching while training,
7.  log sets faster than using a notes app,
8.  see what they did last time,
9.  use rest timers,
10. review workout history,
11. back up their data,
12. continue logging even when the gym internet is poor,
13. and enjoy using the application enough to bring it back to the next
    workout.

The app must feel complete despite being free and backend-free.

Do not hold basic quality back for a hypothetical Pro version.

------------------------------------------------------------------------

# 50. FINAL PRODUCT TEST

Before stopping, ask one question:

> **If I were standing beside a bench in a busy gym with one hand on a
> dumbbell and the other holding my iPhone, would TubeTrainer make the
> next 30 seconds easier?**

If the answer is no, simplify it.

And then ask:

> **When I find the best 30-second explanation of an exercise I've ever
> seen, does TubeTrainer make saving and finding it again feel
> obvious?**

If the answer is no, fix that too.

Those two experiences are the product.

------------------------------------------------------------------------

# 51. FINAL EXECUTION INSTRUCTION TO CLAUDE

Build the complete V1 described above.

Do not wait for additional design decisions where a sensible, reversible
decision can be made from this PRD.

Do not repeatedly ask for permission to proceed between implementation
phases.

Use the TubeTrainer brand and supplied icon as the aesthetic anchor.

Where YouTube/platform behavior requires current documentation, verify
the current official requirements before implementing that integration.

Never fake functionality to satisfy a checkbox.

When a limitation exists, implement the best real fallback.

Run the application throughout development.

Fix issues as they are discovered.

Continue until the principal flows work end-to-end and the project is in
a state suitable for real device testing.

**The target is not "the code exists."**

**The target is: Chris can install TubeTrainer on his iPhone, take it to
the gym, use it for a real workout, and immediately know what needs
improving next.**
