# CosmIQ Guru

A cosmic divination app built with Flutter. Combines 7 ancient and modern divination systems into a unified daily guidance experience with real calculation engines.

## Architecture

- **Platform**: Flutter 3.41+ (Android APK)
- **State**: Provider (ChangeNotifier) via `UserProfileProvider`
- **Database**: sqflite for user profile persistence
- **Preferences**: SharedPreferences for onboarding state + AI API key storage
- **HTTP**: `http` package for LLM API calls (OpenAI/Anthropic)
- **Fonts**: Cinzel (titles), Raleway (body)
- **Theme**: Dark cosmic theme (`0xFF0F0A1A` background, `0xFF7C3AED` purple accent, `0xFFF59E0B` gold accent)

## Project Structure

```
lib/
  main.dart                          # App entry, MultiProvider setup
  engines/                           # Pure calculation engines (no UI, no dependencies)
    archetype_engine.dart            # 12 Jungian archetypes, quiz scoring
    astrology_engine.dart            # Sun/Moon/Rising signs, daily transits
    chinese_zodiac_engine.dart       # 12 animals, 5 elements, inner/secret animals
    decision_engine.dart             # Lucky Decision Engine — 7-system composite for specific questions
    lunar_engine.dart                # Moon phases, void-of-course, monthly calendar
    mahabote_engine.dart             # Burmese 8-day system, Dasa periods
    numerology_engine.dart           # Life path, expression, soul urge, personal day
    planetary_hours_engine.dart      # Chaldean planetary hours, benefic windows
    wealth_engine.dart               # Lucky numbers, investment scoring, wealth cycles, business timing
    ritual_engine.dart               # Ritual calendar, daily ritual suggestions, upcoming cosmic dates
    name_engine.dart                 # Name numerology: scoring, baby names, business names
  services/
    ai_advice_service.dart           # LLM-powered personalised cosmic advice (OpenAI + Anthropic)
    cosmic_service.dart              # Adapter layer: parses user data, delegates to engines
    database_service.dart            # sqflite singleton
    notification_service.dart        # Local notifications
    streak_service.dart              # Daily usage streak tracking
  providers/
    user_profile_provider.dart       # ChangeNotifier with UserProfile model
  screens/
    splash_screen.dart               # 1-second splash, routes to onboarding or main
    onboarding_name_screen.dart      # Step 1: Enter name
    onboarding_birth_screen.dart     # Step 2: DOB (DatePicker), birth time (TimePicker), location
    onboarding_quiz_screen.dart      # Step 3: 12-question Jungian archetype quiz
    onboarding_loading_screen.dart   # Saves profile, computes all engine data, navigates to main
    main_shell.dart                  # Bottom nav: Home, Explore, Compatibility, Settings
    home_screen.dart                 # Luck gauge, energy meters, daily summary, decision window
    luck_breakdown_screen.dart       # 7-system composite score, stacked bar chart, system cards
    decision_engine_screen.dart      # Lucky Decision Engine — ask questions, get cosmic verdict + AI advice
    astrology_screen.dart            # Sun/Moon/Rising signs, transits, horoscope
    numerology_screen.dart           # Life path, expression, soul urge, personality numbers
    chinese_zodiac_screen.dart       # Animal, element, inner/secret animals, trine, compatibility
    mahabote_screen.dart             # Birth day, planet, direction, octagon chart, Dasa period
    lunar_screen.dart                # Moon phase, sign, void-of-course, monthly calendar
    archetype_screen.dart            # Archetype profile: strengths, challenges, shadow, affirmation
    planetary_hours_screen.dart      # Current hour, best windows, 24-hour day/night grid
    compatibility_screen.dart        # Partner compatibility across all 5 systems (romantic + business modes)
    wealth_screen.dart               # Lucky numbers, 7-day forecast, wealth cycle, business timing
    rituals_screen.dart              # Ritual calendar, today's ritual, upcoming cosmic dates
    name_numerology_screen.dart      # Name scorer, baby name generator, business name scorer
    journal_screen.dart              # Cosmic journal: mood, tags, notes, daily cosmic context
    trends_screen.dart               # Trend charts: luck line, mood vs luck scatter, stats, moon correlation
    settings_screen.dart             # Profile display, clear data, app info, AI API key config
  widgets/
    star_background.dart             # Animated star field (CustomPainter)
    luck_gauge.dart                  # Circular gauge with animated fill
```

## 7 Divination Systems

| System | Engine | Score Weight | Key Data |
|--------|--------|-------------|----------|
| Western Astrology | `astrology_engine.dart` | 18% | Sun/Moon/Rising signs, daily transits |
| Numerology | `numerology_engine.dart` | 18% | Life path, expression, soul urge, personal day |
| Chinese Zodiac | `chinese_zodiac_engine.dart` | 13% | Animal, element, yin/yang, inner/secret animals |
| Burmese Mahabote | `mahabote_engine.dart` | 17% | 8-day system, planet, direction, Dasa period |
| Lunar Phase | `lunar_engine.dart` | 14% | Moon phase, sign, void-of-course |
| Jungian Archetype | `archetype_engine.dart` | 10% | 12 archetypes from quiz, daily resonance |
| Planetary Hours | `planetary_hours_engine.dart` | 10% | Chaldean hours, benefic/malefic windows |

## Onboarding Flow

```
SplashScreen → OnboardingNameScreen → OnboardingBirthScreen → OnboardingQuizScreen → OnboardingLoadingScreen → MainShell
```

- DOB passed as ISO format (`1985-02-21`)
- Birth time passed as 24h format (`14:00`)
- Quiz answers stored as JSON array of 12 ints (0-3)
- Loading screen computes all engine data and saves to sqflite

## Key Implementation Notes

- **DOB format**: Birth screen passes ISO `YYYY-MM-DD` via `DateTime.toIso8601String().split('T').first`. CosmicService `_parseDob()` has fallbacks for human-readable format ("February 21, 1985") and slash/dash formats.
- **Birth time format**: Birth screen passes 24h `HH:MM`. CosmicService `_parseBirthHour()` handles AM/PM fallback.
- **Archetype names**: Engine names include "The" prefix (e.g., "The Hero"). Use `archetypeShortName` (strips "The ") when embedding in sentences to avoid "The The Hero".
- **Chinese Zodiac trineGroup**: Engine returns `trineGroup` (int) and `trineGroupName` (String). Use `trineGroupName` for display.
- **Star background**: `StarBackground` widget used as first child in Stack on every screen.
- **Color API**: Uses `withValues(alpha:)` not deprecated `withOpacity()`.

## Build

```bash
# Dev
flutter run

# Release APK
flutter clean && flutter build apk --release

# Install on device
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Phase 2A: Lucky Decision Engine (COMPLETE)

The killer feature — users ask "Is today good for X?" and get a personalised cosmic verdict powered by all 7 divination systems + AI-generated advice.

### Decision Engine (`decision_engine.dart`)
- Category-weighted scoring: each of 8 categories (Business, Investment, Love, Travel, Health, Education, Property, General) has custom weights across all 7 systems
- **Question-aware scoring**: question text is hashed (djb2) into a seed (0-9999), then spread via LCG into 7 independent modifiers (-12 to +12 per system). Different questions produce different scores.
- Outputs: composite score (0-100), risk level, best window, lucky number/color/direction, per-system breakdown, fallback advice text
- Decision history stored in `decision_history` table (sqflite DB v2)

### AI Advice (`ai_advice_service.dart`)
- Supports OpenAI (GPT-4o-mini) and Anthropic (Claude Haiku 4.5) providers
- API key + provider stored in SharedPreferences (`ai_api_key`, `ai_provider`), configured in Settings
- Rich prompt includes question, category, score, risk, moon phase, archetype, best window, lucky attributes, all 7 system scores
- Falls back to templated advice if no API key configured or on error
- 15-second timeout on API calls

### Decision Engine Screen (`decision_engine_screen.dart`)
- Text field + 8-category selector + date picker + "Consult the Cosmos" button
- Animated loading indicator ("Reading the cosmic energies...")
- Result card: large score display, score bar, 6 stat chips (best window, lucky #, color, direction, risk, category), 7-system breakdown bars, cosmic advice section
- **AI advice loading**: shows shimmer placeholder ("Channelling cosmic wisdom...") while AI generates, then smoothly replaces with personalised advice — no flash of canned text
- Swipe-to-delete decision history below results

### Key Implementation Details
- `_questionSeed()`: djb2 hash of normalized question → 0-9999
- `_questionModifiers()`: LCG spreads seed into 7 values, each -12 to +12, added to engine scores before clamping
- Lucky number/color/direction all incorporate question seed for variation
- `bestWindow` composed from 3 separate engine keys: `bestWindowStart`, `bestWindowEnd`, `bestWindowPlanet`
- System bars use capitalized keys (`'Astrology'`, `'Chinese Zodiac'`, `'Planetary Hours'`)
- `_isLoadingAiAdvice` state flag controls shimmer vs advice text display

## Phase 2B: Wealth & Money Mode + Rituals Calendar (COMPLETE)

Two new features adding daily financial utility and ritual guidance beyond basic horoscope readings.

### Wealth Engine (`wealth_engine.dart`)
- **Lucky Numbers**: 3 daily numbers derived from personal day + life path + expression number
- **Investment Day Score**: 0-100 composite from numerology (day 8=money), lunar phase (waxing=growth), planetary hours (Jupiter/Venus=wealth), Chinese element cycle
- **7-Day Forecast**: week-ahead financial scores with green/amber/red ratings
- **Wealth Cycle**: personal year number (1-9) mapped to growth/consolidation/harvest phases with peak months
- **Business Timing**: scans month for best days to sign contracts, launch products, negotiate deals, ask for raises
- **Risk Appetite**: daily conservative-to-aggressive risk score with advice

### Ritual Engine (`ritual_engine.dart`)
- **Day Classification**: each day classified as START (waxing+1/3/5), END (waning+9), CLEANSE (new moon+4), or REFLECT (full moon+7)
- **Ritual Score**: 0-100 strength based on moon phase, personal day alignment, planetary ruler
- **Monthly Calendar**: color-coded ritual calendar with per-day type and score
- **Today's Ritual**: specific suggestion + explanation combining moon phase and numerology context
- **Upcoming Dates**: next new/full moon, personal year change, next high-energy day

### Wealth Screen (`wealth_screen.dart`)
- Lucky numbers in gold circles + lucky wealth color
- Investment mood gauge with risk label and advice
- 7-day forecast with colored progress bars and moon phase emojis
- Wealth cycle card showing phase, peak months, Chinese element context
- Business timing section with 4 categories (contracts, launches, negotiations, raises) and tagged best days

### Rituals Screen (`rituals_screen.dart`)
- Today's ritual card with type badge, suggestion box, and moon/numerology explanation
- Monthly ritual calendar with color-coded days (tap any day for detail bottom sheet)
- Legend row with 4 ritual types
- Upcoming key cosmic dates with countdown badges

### Navigation
- Two quick-access cards on Home screen ("Money Mode" + "Rituals") below Lucky Details
- Both screens accessible via Navigator.push from Home

## Phase 2C: Business Compatibility + Name Numerology (COMPLETE)

Business partnership matching and comprehensive name numerology tools.

### Name Engine (`name_engine.dart`)
- **Name Scoring**: expression number (full name), soul urge (vowels), personality number (consonants), compatibility with user's life path
- **Baby Name Generator**: ~120 name database with gender/origin filters, scored against both parents' life path numbers, returns top 20
- **Business Name Scorer**: expression number + owner alignment, lucky pricing numbers, best launch days (next 30 days scanned)

### Business Compatibility (`cosmic_service.dart` — `getBusinessCompatibility()`)
- 5 scoring dimensions: expression numbers, life path, Chinese zodiac, Mahabote, archetype compatibility
- 4 partnership types with different weight profiles:
  - **Co-founder**: heavy on complementary expression numbers + archetype compatibility
  - **Employee**: focus on Mahabote work direction + archetype fit
  - **Business Partner**: numerology + Chinese zodiac element harmony
  - **Investor**: wealth numerology alignment

### Compatibility Screen (`compatibility_screen.dart`)
- Romantic/Business mode toggle at top of form (purple for romantic, gold for business)
- Partnership type selector chips when in business mode
- Mode-aware labels, button text, and scoring display
- Fixed existing bug: system score cards reading wrong key (`'detail'` vs `'description'`)

### Name Numerology Screen (`name_numerology_screen.dart`)
- 3-tab interface via TabController: Score, Baby Names, Business
- **Score tab**: text input → score circle + 3 number badges (expression, soul urge, personality) + compatibility text
- **Baby Names tab**: surname + gender/origin filters → ranked list of 20 names with scores and meanings
- **Business tab**: business name → score + lucky pricing chips + best launch days

### Navigation
- "Name Scorer" quick-access card on Home screen (blue, below Money Mode/Rituals row)

## Phase 2D: Cosmic Journal + Trend Charts (COMPLETE)

Daily mood journaling with cosmic context and trend visualization over time.

### Journal Screen (`journal_screen.dart`)
- **Mood picker**: 5 emoji levels (Terrible→Amazing, index 0-4)
- **Quick tags**: 9 toggleable tags (Good sleep, Bad sleep, Productive, Stressed, Lucky, Social, Quiet day, Exercise, Travel)
- **Note field**: optional 140-character free text with live counter
- **Cosmic context card**: auto-attaches today's luck score, moon phase, and dominant system
- **Save/update**: detects if today's entry already exists, updates in place
- **History list**: scrollable past entries with mood emoji, date, luck badge, tags, note, moon phase, dominant system

### Trends Screen (`trends_screen.dart`)
- **Range selector**: 7 / 30 / 90 day toggle
- **Luck Score Trend**: LineChart with curved line, dots for ≤14 days, gradient fill (fl_chart)
- **Mood vs Luck**: ScatterChart with mood emoji Y-axis, gold dots (fl_chart)
- **Stats cards**: best/worst day of week (with averages), average luck, average mood
- **Moon Phase & Mood**: horizontal bar correlation chart grouped by moon phase
- **System Dominance**: percentage bars showing which divination system was dominant most often
- **Empty state**: shown when no journal entries exist for selected range
- **Data source**: all charts use saved journal entry data only (engines use `DateTime.now()` internally, cannot compute historical scores)

### Database (`database_service.dart`)
- `JournalEntry` model: id, userId, date, mood, tagsJson, note, luckScore, moonPhase, dominantSystem, createdAt
- DB version 2→3 migration: creates `journal_entries` table
- 5 CRUD methods: save, get by date, get all, get range, delete

### Navigation
- "Journal" quick-access card on Home screen (green, paired with Name Scorer)
- Trends screen accessible via chart icon in Journal app bar

## Post-Build Fixes Applied

1. **DOB parsing** — Birth screen was passing human-readable format; `_parseDob()` fell back to Jan 1 2000 (Capricorn). Fixed to ISO format + enhanced parser with human-readable fallback.
2. **Chinese Zodiac crash** — `trineGroup` cast as String but engine returns int. Fixed to use `trineGroupName`.
3. **Birth time AM/PM** — "2:00 PM" parsed as hour 2 instead of 14. Fixed with AM/PM detection in `_parseBirthHour()`.
4. **"The The Hero" double-The** — Archetype names include "The" prefix. Template strings added another "The". Fixed by stripping prefix with `archetypeShortName`.
5. **Archetype/Planetary Hours bottom sheets** — Only showed simple info panels. Created proper full-screen detail views (`archetype_screen.dart`, `planetary_hours_screen.dart`).
6. **flutter clean required** — Build cache didn't pick up source changes. Always run `flutter clean` before release builds after code changes.
7. **Decision Engine stuck spinner** — 3 root causes: (a) no try/catch in `_consultCosmos()`, (b) `bestWindow` key mismatch (screen expected single key, engine returns 3 separate keys), (c) `_buildSystemBars` used lowercase keys but engine returns capitalized.
8. **Same scores for every question** — Question text was stored but never used in calculation. Fixed with djb2 hash → seed → 7 per-engine modifiers.
9. **Canned advice text** — `_generateAdvice()` was pure string concatenation. Replaced with `AiAdviceService` calling OpenAI/Anthropic with full cosmic context.
10. **Flash of canned advice before AI response** — Result card showed fallback text immediately, then replaced 2-3s later. Fixed with `_isLoadingAiAdvice` flag and shimmer placeholder.
