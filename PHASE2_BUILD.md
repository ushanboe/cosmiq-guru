# CosmIQ Guru — Phase 2 Build Document

**Version**: 2.0 (from v1.0 shell)
**Date**: 2026-03-14
**Approach**: AppForge built the v1.0 shell. All Phase 2 work is manual Claude Code builds.

---

## What Exists (v1.0)

### Current Architecture
- 7 pure calculation engines in `lib/engines/` (no UI deps)
- `CosmicService` static adapter layer — parses user data, delegates to engines
- `UserProfileProvider` (ChangeNotifier) — profile + zodiac + theme
- `DatabaseService` (sqflite v1) — 6 tables: user_profiles, zodiac_profiles, daily_readings, compatibility_results, app_settings, streak_records
- 17 screens, 4-tab bottom nav (Home, Explore, Match, Settings)

### Current Features
- Daily Luck Score (0-100 composite from 7 engines)
- Decision Window (best planetary hour)
- 3 Energy Meters (Relationship, Money, Career)
- 7 system detail screens (Astrology, Numerology, Chinese Zodiac, Mahabote, Lunar, Archetype, Planetary Hours)
- Romantic Compatibility (partner DOB → 5-system comparison)
- Daily streak tracking
- Notifications
- Share compatibility results

### What's NOT Built (from original vision)
1. Lucky Decision Engine — user asks "Is today good for X?"
2. Wealth & Money Astrology — investment timing, lucky numbers, wealth cycles
3. Personalized Rituals — best days for cleansing, habits, quitting
4. Business Compatibility — co-founder, employee, partner matching
5. Name Numerology — baby names, business names, name scoring
6. Business/Entrepreneur Mode — launch timing, pricing numbers, logo dates
7. Cosmic Journal — daily mood logging + correlation with readings

---

## Phase 2 Feature Plan

### Phase 2A: Lucky Decision Engine (HIGH IMPACT) — COMPLETE
**The killer feature.** Users input a specific decision and get a personalized cosmic verdict.

#### New Screen: `decision_engine_screen.dart`
**Navigation**: New 5th tab in bottom nav — replace current 4-tab with 5-tab. Icon: `auto_fix_high` or `psychology`. Label: "Decide"

**User Flow**:
1. User taps "Decide" tab
2. Sees a text field + category picker
3. Types a decision: "Start a business", "Sign contract", "Travel to Japan", "Propose to Sarah"
4. Picks a category from presets OR types custom:
   - Business & Career
   - Money & Investment
   - Love & Relationships
   - Travel
   - Health & Wellness
   - Education
   - Property & Real Estate
   - General
5. Optionally picks a target date (default: today)
6. Taps "Consult the Cosmos"
7. Animated loading (2-3 seconds, cosmic particles)
8. Results card appears:

```
┌─────────────────────────────────────┐
│          🎯 COSMIC VERDICT          │
│                                     │
│     "Start a business"              │
│                                     │
│        LUCK SCORE: 83              │
│     ████████████░░░  83/100        │
│                                     │
│  ⏰ Best Window: 3:20 – 5:10 PM    │
│  🔢 Lucky Number: 7                │
│  🎨 Lucky Color: Gold              │
│  ⚠️ Risk Level: LOW                │
│  🧭 Lucky Direction: Southeast     │
│                                     │
│  ── System Breakdown ──             │
│  ♈ Astrology:     78  ████████░    │
│  🔢 Numerology:   91  █████████░   │
│  🐉 Chinese:      72  ███████░░    │
│  🌙 Lunar:        88  █████████░   │
│  🇲🇲 Mahabote:    85  ████████░    │
│  🎭 Archetype:    76  ████████░    │
│  ⏳ Planetary:    92  █████████░   │
│                                     │
│  ── Cosmic Advice ──                │
│  "The stars strongly favor bold     │
│   action today. Jupiter's transit   │
│   through your 10th house combined  │
│   with a waxing moon and your       │
│   personal day number 1 creates     │
│   powerful initiating energy..."    │
│                                     │
│  [📤 Share]  [📅 Save to Calendar]  │
└─────────────────────────────────────┘
```

#### New Engine: `decision_engine.dart`
Pure calculation engine — no UI, no deps. Takes category + target date + user birth data.

**Inputs**: `String category, DateTime targetDate, DateTime dob, String fullName, int birthHour, int archetypeId`

**Calculation Logic**:
```
categoryWeight = {
  'business':    { astrology: 0.20, numerology: 0.25, chinese: 0.15, mahabote: 0.15, lunar: 0.10, archetype: 0.05, planetary: 0.10 },
  'investment':  { astrology: 0.15, numerology: 0.30, chinese: 0.15, mahabote: 0.10, lunar: 0.10, archetype: 0.05, planetary: 0.15 },
  'love':        { astrology: 0.30, numerology: 0.15, chinese: 0.15, mahabote: 0.10, lunar: 0.15, archetype: 0.10, planetary: 0.05 },
  'travel':      { astrology: 0.15, numerology: 0.10, chinese: 0.15, mahabote: 0.25, lunar: 0.15, archetype: 0.05, planetary: 0.15 },
  'health':      { astrology: 0.20, numerology: 0.10, chinese: 0.10, mahabote: 0.15, lunar: 0.25, archetype: 0.10, planetary: 0.10 },
  'education':   { astrology: 0.15, numerology: 0.20, chinese: 0.10, mahabote: 0.15, lunar: 0.10, archetype: 0.20, planetary: 0.10 },
  'property':    { astrology: 0.15, numerology: 0.25, chinese: 0.20, mahabote: 0.15, lunar: 0.10, archetype: 0.05, planetary: 0.10 },
  'general':     { astrology: 0.18, numerology: 0.18, chinese: 0.13, mahabote: 0.17, lunar: 0.14, archetype: 0.10, planetary: 0.10 },
}
```

Each engine scores the target date (not today — use targetDate):
- Astrology: transit quality for category (e.g., Jupiter/Venus transits boost business/love)
- Numerology: personal day number alignment with category (1=starts, 8=money, 6=love)
- Chinese: element cycle compatibility for date
- Mahabote: Dasa period + day ruler alignment
- Lunar: moon phase suitability (waxing=start, waning=end, full=peak, new=plan)
- Archetype: archetype resonance with category
- Planetary Hours: best window within the day

**Output**: `Map<String, dynamic>` with:
- `score` (int 0-100) — weighted composite
- `riskLevel` (String) — Low/Medium/High/Extreme based on score bands
- `bestWindowStart`, `bestWindowEnd` (String) — from planetary hours for category
- `luckyNumber` (int) — numerology personal day + category modifier
- `luckyColor` (String) — from astrology element + category
- `luckyDirection` (String) — from Mahabote
- `systemScores` (Map<String, int>) — individual system scores
- `advice` (String) — 2-3 sentence generated narrative explaining why

#### New Method: `CosmicService.getDecisionReading()`
Adapter in cosmic_service.dart that:
1. Parses user profile (DOB, name, birth hour, archetype)
2. Calls `DecisionEngine.calculate(category, targetDate, ...)`
3. Returns formatted result map

#### DB: `decision_history` table (new, DB version 2)
```sql
CREATE TABLE decision_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  decision_text TEXT NOT NULL,
  category TEXT NOT NULL,
  target_date TEXT NOT NULL,
  score INTEGER NOT NULL,
  risk_level TEXT NOT NULL,
  lucky_number INTEGER NOT NULL,
  best_window TEXT NOT NULL,
  scores_json TEXT NOT NULL,
  advice TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user_profiles (id)
);
```

#### Decision History
Below the input area, show a scrollable list of past decisions with score badges. Tap to re-view full result.

#### Phase 2A Implementation Notes (2026-03-14)

**Built files:**
- `lib/engines/decision_engine.dart` — Pure calculation engine with category-weighted scoring
- `lib/services/ai_advice_service.dart` — LLM API integration (OpenAI GPT-4o-mini + Anthropic Claude Haiku 4.5)
- `lib/screens/decision_engine_screen.dart` — Full result card UI with animated loading

**Enhancements beyond spec:**
- **Question-aware scoring**: djb2 hash of question text → seed → 7 per-engine modifiers (-12 to +12) via LCG. Different questions produce meaningfully different scores.
- **AI-generated personalised advice**: replaces templated string concatenation with LLM API call using full cosmic context (question, category, score, risk, moon phase, archetype, lucky attributes, all 7 system scores). Configured via Settings screen (API key + provider).
- **Shimmer loading state**: Cosmic Advice section shows "Channelling cosmic wisdom..." with placeholder shimmer lines while AI generates, preventing flash of canned text.
- **Graceful fallback**: If no API key configured or API error, shows templated advice instead.

**Key fixes applied:**
1. Stuck spinner — missing try/catch, bestWindow key mismatch (3 keys vs 1), system bar label case mismatch
2. Same scores for every question — question text hashing with per-engine modifiers
3. Flash of canned advice — `_isLoadingAiAdvice` state flag with shimmer placeholder

---

### Phase 2B: Wealth & Money Mode + Rituals Calendar — COMPLETE

#### New Screen: `wealth_screen.dart`
Accessible from Home screen (new "Money Mode" card) or from a new section in Explore.

**Shows**:
- **Lucky Investment Days** — next 7 days scored for financial decisions (mini calendar, color-coded green/amber/red)
- **Wealth Cycle** — current position in personal wealth cycle (numerology personal year + Chinese element cycle). "You're in a Growth year — expansion energy peaks in months 3, 7, 11"
- **Lucky Numbers** — 3 lucky numbers for today (from numerology personal day + life path + expression number)
- **Business Timing** — best days this month for: signing contracts, launching products, negotiating deals, asking for raises
- **Crypto/Investment Mood** — daily risk appetite score (conservative/moderate/aggressive) based on lunar + planetary alignment

#### New Engine: `wealth_engine.dart`
**Methods**:
- `luckyNumbers(DateTime dob, String fullName, DateTime date)` → `List<int>` (3 numbers)
- `investmentDayScore(DateTime dob, DateTime date)` → `int` (0-100)
- `weekForecast(DateTime dob, String fullName, DateTime startDate)` → `List<Map>` (7 days with scores)
- `wealthCycle(DateTime dob, DateTime date)` → `Map` (cycle phase, description, peak months)
- `businessTiming(DateTime dob, DateTime date)` → `Map` (best days for each action type)

**Calculation approach**:
- Lucky numbers: personal day number + life path + expression number, modulo and combination formulas
- Investment score: numerology personal day (8,1 = strong) + lunar phase (waxing = growth) + planetary hour ruler (Jupiter/Venus = wealth) + Chinese element cycle
- Wealth cycle: personal year number (1-9 cycle) mapped to growth/consolidation/harvest phases
- Business timing: scan next 30 days, score each for specific activities using existing engines

#### New Screen: `rituals_screen.dart`
Accessible from Home screen (new "Rituals" card) or Explore.

**Shows**:
- **Monthly Ritual Calendar** — calendar view with color-coded days:
  - 🟢 Best days to START things (new habits, projects, diets) — waxing moon + numerology 1/3/5
  - 🔴 Best days to END things (quit smoking, break up, resign) — waning moon + numerology 9
  - 🟡 Best days to CLEANSE (energy clearing, declutter, detox) — new moon + certain planetary hours
  - 🔵 Best days for REFLECTION (meditation, journaling, planning) — full moon + numerology 7
- **Today's Ritual Suggestion** — "Today is ideal for starting new habits. The waxing crescent moon combined with your personal day 3 creates strong creative/initiation energy."
- **Upcoming Key Dates** — next new moon, full moon, personal year change, lucky day

#### New Engine: `ritual_engine.dart`
**Methods**:
- `monthCalendar(DateTime dob, String fullName, int month, int year)` → `List<Map>` (day + ritualType + score + description)
- `todayRitual(DateTime dob, String fullName)` → `Map` (type, suggestion, score)
- `upcomingDates(DateTime dob)` → `List<Map>` (date, event, description)

#### Phase 2B Implementation Notes (2026-03-14)

**Built files:**
- `lib/engines/wealth_engine.dart` — Composite engine combining numerology, lunar, planetary hours, and Chinese zodiac for financial timing. 7 methods: `luckyNumbers`, `investmentDayScore`, `weekForecast`, `wealthCycle`, `businessTiming`, `riskAppetite`, `luckyWealthColor`.
- `lib/engines/ritual_engine.dart` — Cosmic rituals engine classifying days as START/END/CLEANSE/REFLECT based on moon phase fraction + personal day number. 3 public methods: `monthCalendar`, `todayRitual`, `upcomingDates`.
- `lib/screens/wealth_screen.dart` — 5 card sections: lucky numbers in gold circles + wealth color, investment mood gauge (risk 0-4), 7-day forecast with progress bars, wealth cycle (personal year phase + Chinese element), business timing with 4 categories and best-day chips.
- `lib/screens/rituals_screen.dart` — Today's ritual card (type badge, suggestion box, explanation), monthly calendar grid with color-coded days + month navigation + tap-for-detail bottom sheet, legend row (4 types), upcoming cosmic dates with countdown badges.
- `lib/screens/home_screen.dart` — Added two quick-access cards ("Money Mode" gold + "Rituals" purple) in a Row, using Navigator.push to detail screens.

**Key algorithms:**
- **Day classification**: Moon phase fraction (waxing <0.5 / waning ≥0.5) combined with personal day number determines ritual type. New Moon → cleanse, Full Moon → reflect, waxing + day 1/3/5 → start, waning + day 9 → end.
- **Investment scoring**: Blends numerology personal day (8=money), lunar phase (waxing=growth), planetary hours (Jupiter/Venus=wealth), Chinese element, and weekday variation into 0-100 score.
- **Business timing**: Scans remaining days in month, filters by void-of-course, matches day ruler + personal day to 4 activity categories (contracts, launches, negotiations, raises).
- **Risk appetite**: 5-level scale (0-4) from conservative to aggressive based on investment score thresholds.

**Fixes applied during build:**
1. Unused import `astrology_engine.dart` in wealth_engine.dart — removed
2. Two unused `type` local variables in rituals_screen.dart — removed

---

### Phase 2C: Business Compatibility + Name Numerology — **COMPLETE**

#### Extend: `compatibility_screen.dart`
Add a **mode toggle** at the top: "Romantic" | "Business"

**Business mode adds**:
- Partnership type picker: Co-founder, Employee, Business Partner, Investor
- Same input (partner name + DOB + birth time)
- Different scoring weights per partnership type:
  - Co-founder: heavy on complementary archetypes + numerology expression numbers
  - Employee: focus on archetype compatibility + mahabote work direction
  - Business Partner: numerology + chinese zodiac element harmony
  - Investor: wealth numerology alignment

**New method**: `CosmicService.getBusinessCompatibility()`
Uses same engines but different weight profiles and different narrative templates.

#### New Screen: `name_numerology_screen.dart`
Accessible from Explore tab or Settings.

**Mode 1: Name Scorer**
- Input: any name (person, business, product)
- Shows: numerology breakdown (expression number, soul urge, personality number)
- Compatibility with user's life path number
- Score: 0-100 "cosmic name alignment"

**Mode 2: Baby Name Generator**
- Input: surname, desired gender (optional), culture/origin (optional)
- Shows: top 10 names ranked by numerology compatibility with parents' birth data
- Each name shows: expression number, compatibility score, meaning snippet

**Mode 3: Business Name Scorer**
- Input: proposed business name
- Shows: expression number, whether it aligns with user's life path
- Best launch date based on name numerology + astrology
- Lucky pricing numbers (from name expression + personal numbers)

#### New Engine: `name_engine.dart`
**Methods**:
- `scoreName(String name, int lifePathNumber)` → `Map` (score, expression, soulUrge, personality, compatibility)
- `generateBabyNames(String surname, DateTime parentDob1, DateTime parentDob2, String culture)` → `List<Map>` (name, score, expressionNumber, meaning)
- `scoreBusinessName(String name, DateTime ownerDob, String ownerName)` → `Map` (score, expressionNumber, luckyLaunchDays, luckyPricing)

Baby name database: hardcoded list of ~200 popular names across cultures with meanings. Scored and ranked by numerology alignment.

#### Phase 2C Implementation Notes (2026-03-14)

**Built files:**
- `lib/engines/name_engine.dart` — Pure name numerology engine with ~120 baby name database. 3 public methods: `scoreName` (expression/soul urge/personality numbers + compatibility), `generateBabyNames` (surname + parent DOBs + gender/origin filters → top 20 ranked names), `scoreBusinessName` (expression number + lucky pricing + best launch days).
- `lib/services/cosmic_service.dart` — Added `getBusinessCompatibility()` method with 5 scoring dimensions (expression numbers, life path, Chinese zodiac, Mahabote, archetype) and per-partnership-type weight profiles (cofounder, employee, partner, investor).
- `lib/screens/compatibility_screen.dart` — Added Romantic/Business mode toggle, partnership type selector chips (Co-founder, Employee, Partner, Investor), mode-aware labels and button text. Fixed existing bug where system score cards read `'detail'` key but data used `'description'`.
- `lib/screens/name_numerology_screen.dart` — 3-tab interface (Score, Baby Names, Business). Score tab: name input → score circle + 3 number badges + compatibility text. Baby Names tab: surname + gender/origin filters → ranked list of 20. Business tab: business name → score + lucky pricing chips + best launch days.
- `lib/screens/home_screen.dart` — Added "Name Scorer" quick access card (blue, 🔤 emoji) below Money Mode/Rituals row.

**Key algorithms:**
- **Name scoring**: Expression number from full name + soul urge from vowels + personality from consonants. Compatibility score blends life path harmony (40%), expression alignment (30%), and master number bonuses (30%).
- **Baby name ranking**: Generates candidates from ~120 name database filtered by gender/origin, scores each against both parents' life path numbers, returns top 20 sorted by composite score.
- **Business name scoring**: Expression number + owner life path harmony. Lucky pricing uses expression + life path digits. Best launch days scan next 30 days for numerology alignment.
- **Business compatibility**: 5 dimensions with partnership-type weights — cofounder emphasises complementary expression numbers + archetype compatibility, employee focuses on Mahabote work direction, investor weights wealth numerology alignment.

**Fixes applied during build:**
1. Duplicate set literal `{5, 5}` in `_harmonious()` method — removed (already handled by `a == b` check above)
2. System score display bug — cards were reading `system['description']` but data had key `'detail'`, now correctly mapped

---

### Phase 2D: Cosmic Journal + Trend Charts — **COMPLETE**

#### Phase 2D Implementation Notes (2026-03-14)

**Built files:**
- `lib/services/database_service.dart` — Added `JournalEntry` model class with JSON tag decoding. DB version 2→3 migration creates `journal_entries` table. 5 CRUD methods: `saveJournalEntry`, `getJournalEntry` (by date), `getJournalEntries` (all DESC), `getJournalEntriesRange` (date range ASC), `deleteJournalEntry`. Added to `clearAll()`.
- `lib/screens/journal_screen.dart` — 5-emoji mood picker (Terrible→Amazing, 0-4), 9 quick tags, optional 140-char note with counter, cosmic context card (today's luck score + moon phase + dominant system auto-attached), save/update detection, scrollable history list with mood emoji + date + luck badge + tags + note + moon phase + dominant system. App bar chart icon navigates to Trends.
- `lib/screens/trends_screen.dart` — Range selector (7/30/90 days), Luck Score Trend LineChart with gradient fill, Mood vs Luck ScatterChart with emoji Y-axis, stats cards (best/worst day of week + avg luck + avg mood), Moon Phase & Mood horizontal bar correlation, System Dominance percentage bars. All data sourced from journal entries only (engines use `DateTime.now()`, cannot compute historical scores). Empty state when no entries.
- `lib/screens/home_screen.dart` — Added "Journal" quick-access card (green, 📓 emoji) paired with Name Scorer in a Row.

**Key design decision:**
- Engines use `DateTime.now()` internally and do not accept a date parameter. Historical luck scores cannot be computed. The Trends screen displays only data from saved journal entries. Each journal entry captures that day's live luck score, moon phase, and dominant system at save time.

**DB schema:**
```sql
CREATE TABLE journal_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  date TEXT NOT NULL UNIQUE,
  mood INTEGER NOT NULL,
  tags TEXT NOT NULL DEFAULT '[]',
  note TEXT,
  luck_score INTEGER NOT NULL DEFAULT 0,
  moon_phase TEXT NOT NULL DEFAULT '',
  dominant_system TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user_profiles (id)
);
```

---

## Implementation Order

| Phase | Features | New Files | Status |
|-------|----------|-----------|--------|
| **2A** | Lucky Decision Engine + AI Advice | 1 engine + 1 service + 1 screen | **COMPLETE** |
| **2B** | Wealth Mode + Rituals | 2 engines + 2 screens | **COMPLETE** |
| **2C** | Business Compat + Names | 1 engine + 1 screen + extend compat | **COMPLETE** |
| **2D** | Journal + Trends | 2 screens + DB migration | **COMPLETE** |

### Recommended Build Order
1. **2A first** — the Lucky Decision Engine is the "Is today good for X?" feature that differentiates the app from every other horoscope app. Ship this and test.
2. **2B next** — Wealth mode and Rituals calendar add daily utility beyond just "reading your horoscope"
3. **2C** — Name numerology is highly shareable/viral (baby names, business names)
4. **2D last** — Journal and trends require accumulated data to be useful, so ship last

---

## Navigation Changes

### Current (v1.0): 4 tabs
```
Home | Explore | Match | Settings
```

### Proposed (v2.0): 5 tabs
```
Home | Decide | Explore | Match | Settings
```

The Decide tab is the Lucky Decision Engine — the headline feature.

Wealth, Rituals, Journal, Trends, and Name Numerology are accessed via cards on the Home screen or from the Explore tab (added as new cards/sections in luck_breakdown_screen.dart).

---

## DB Migration Strategy

Bump database version from 1 → 2 in `database_service.dart`.

`_onUpgrade` adds new tables only (existing tables untouched):
```dart
if (oldVersion < 2) {
  await db.execute('CREATE TABLE IF NOT EXISTS decision_history (...)');
  await db.execute('CREATE TABLE IF NOT EXISTS journal_entries (...)');
}
```

---

## Theme & Style Rules
- All new screens follow existing pattern: `Scaffold > Stack[StarBackground, CustomScrollView]`
- Dark cosmic theme: `0xFF0F0A1A` bg, `0xFF1A1025` cards, `0xFF7C3AED` purple, `0xFFF59E0B` gold
- Fonts: Cinzel (titles/headers), Raleway (body)
- Color API: `withValues(alpha:)` not `withOpacity()`
- Cards: `_buildCard()` helper with border color parameter
- Chips: `_buildChipList()` for tag-style lists
- All engines: pure Dart, no UI, no dependencies, static methods

---

## Key Gotchas (carry forward from v1.0 + Phase 2A)
- **DOB format**: Always ISO `YYYY-MM-DD`. Parse with `DateTime.parse()` + fallbacks.
- **Birth time**: Always 24h `HH:MM`. Parse with AM/PM fallback.
- **Archetype names**: Include "The" prefix. Use `archetypeShortName` to strip when embedding in sentences.
- **trineGroup**: Engine returns int, use `trineGroupName` (String) for display.
- **flutter clean**: ALWAYS run before release build after code changes.
- **Color API**: `withValues(alpha:)` not deprecated `withOpacity()`.
- **StarBackground**: First child in Stack on every screen.
- **DB migration**: Use try/catch ALTER TABLE for safe column additions on existing installs.
- **Decision Engine bestWindow**: Engine returns 3 separate keys (`bestWindowStart`, `bestWindowEnd`, `bestWindowPlanet`), NOT a single `bestWindow` key. Screen must compose them.
- **Decision Engine system score keys**: Engine returns capitalized keys (`'Astrology'`, `'Chinese Zodiac'`, `'Planetary Hours'`), not lowercase.
- **AI advice async pattern**: Show shimmer placeholder while AI loads, not fallback text. Use `_isLoadingAiAdvice` state flag to prevent flash of canned content.
- **AI API config**: Stored in SharedPreferences as `ai_api_key` (String) and `ai_provider` (String: `'OpenAI'` or `'Anthropic'`). Configured in Settings screen.
- **Engine date limitation**: All engines use `DateTime.now()` internally — they do NOT accept a date parameter. Historical luck scores cannot be computed retroactively. Journal entries capture live scores at save time; Trends screen only displays data from saved entries.
- **DB version 3**: Journal entries table added in v3 migration. `_onUpgrade` uses `if (oldVersion < 3)` guard.
