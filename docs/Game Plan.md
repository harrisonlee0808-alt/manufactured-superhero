# Game Plan - Manufactured Superhero

## Purpose of this document

This document is the single source of truth for the game direction and design constraints.
When making implementation decisions, use this document as the authority.
If code behavior and this document conflict, update code to match this document (unless a future version of this document explicitly changes the rule).

## Core game identity (non-negotiable)

- Genre: top-down 2D arena survival + wave combat + roguelite card progression.
- Camera: fixed to arena, no scrolling.
- Arena shape: rectangular "box arena" where each edge aligns to screen edges.
- Visible border/UI lane: there must be a border area around the playable arena for UI readability.
- Session structure: endless wave progression until player fails.
- Loss condition: failing any wave ends the run immediately.
- Score: high score is the highest completed wave reached before death.
- Boss loop: each boss kill grants exactly 1 good card and 1 bad card, both random.

## Screen layout and spatial rules

## Resolution assumptions

- Baseline internal resolution: 1920x1080 (scale to other resolutions).
- Keep all gameplay coordinates resolution-independent (normalized or scaled constants).

## Arena and UI border

- The playable arena is an inset rectangle inside the screen.
- Recommended baseline margins:
  - Top UI border: 96 px
  - Bottom UI border: 96 px
  - Left UI border: 72 px
  - Right UI border: 72 px
- Playable arena rect at 1920x1080:
  - X: 72 to 1848
  - Y: 96 to 984
- Draw a clear arena border line (2-4 px thick) so bounds are obvious.
- Player and enemies cannot pass through border line.

## Coordinate conventions

- World origin: top-left of screen.
- Positive X: right, Positive Y: down.
- Arena collision uses axis-aligned rectangle clamp.

## Core run loop

1. Start run (wave = 1, no powers, base weapon available).
2. Spawn wave enemies.
3. Player defeats all normal enemies.
4. If wave is boss wave, spawn boss and require boss defeat.
5. On boss kill:
   - Offer 1 random good card.
   - Offer 1 random bad card.
   - Player must take both (order can be player-selected but both are mandatory).
6. Increment wave number.
7. Repeat until player dies.
8. On death:
   - End run.
   - Record high score if this run exceeded previous max wave completed.

## Wave structure and boss cadence

- Wave numbers start at 1.
- Boss appears every 5 waves: 5, 10, 15, ...
- Non-boss waves:
  - Clear condition: all enemies defeated.
- Boss waves:
  - Spawn a mixed pack of standard enemies first (reduced count vs normal same-tier wave).
  - Spawn boss once pack count is reduced to 0.
  - Clear condition: boss defeated (and no remaining adds).

## Difficulty scaling baseline

- Enemy count base formula:
  - normalEnemyCount = 4 + floor((wave - 1) * 1.25)
- Enemy stat scaling per wave:
  - healthMultiplier = 1.0 + 0.08 * (wave - 1)
  - damageMultiplier = 1.0 + 0.06 * (wave - 1)
  - moveSpeedMultiplier = 1.0 + 0.015 * (wave - 1), capped at 1.6
- Boss stat scaling:
  - bossHealthMultiplier = 1.0 + 0.18 * (bossIndex - 1)
  - bossDamageMultiplier = 1.0 + 0.12 * (bossIndex - 1)
  - bossIndex = wave / 5

## Player baseline

## Starting loadout

- Player starts with one basic melee option:
  - Option A: fists (default if no starting weapon select exists)
  - Option B: sword (if implemented as default starter)
- If both exist, fists are fallback when sword unavailable.
- Initial powers: none.

## Base player stats

- Max HP: 100
- Move speed: 280 px/s
- Contact invuln after hit: 0.45 s
- Melee attack rate:
  - fists: 2.2 attacks/s
  - sword: 1.4 attacks/s
- Base melee reach:
  - fists: 54 px
  - sword: 86 px

## Combat entities and required behavior

## Enemy archetypes (minimum set)

- Grunt:
  - melee chaser, short windup.
- Warrior:
  - default weapon = sword unless modified by bad card.
- Runner:
  - lower HP, faster move speed, low damage.
- Tank:
  - higher HP, slower move speed.

## Boss behavior constraints

- Boss must be visually and behaviorally distinct from normal enemies.
- Boss should have at least:
  - one melee threat zone attack
  - one telegraphed special attack
- Boss cannot be stun-locked permanently.
- Boss must be targetable by all base and power attacks.

## Combat rules

- All attacks use consistent hit timing (windup -> active -> recovery).
- Collision/hit processing must prevent multi-hit in the same frame unless explicitly intended.
- Damage numbers optional, but hit feedback mandatory (flash, knockback, or sound cue).

## Cards system design

## Card trigger

- Card event occurs immediately after each boss defeat.
- Exactly one good and one bad card are selected randomly.
- Player must accept both cards before next wave starts.

## Randomization rules

- Maintain separate pools:
  - goodCardPool
  - badCardPool
- Avoid identical repeat of the same card within the same run until pool exhausted (soft no-repeat).
- If pool exhausted, reset pool and continue.

## Good card philosophy

- Good cards grant increasingly impactful powers from simple movement/combat modifiers to complex active abilities.
- Good cards should feel empowering but not guaranteed run-winning.

## Bad card philosophy

- Bad cards increase challenge in measurable, specific ways.
- Bad cards should never create impossible states alone.
- Stacking multiple bad cards can become extreme over long runs.

## Mandatory example cards (minimum implementation set)

### Good cards (at least these)

1. Stick to Walls
   - Player can cling to arena walls for up to 1.2 s.
   - While clinging: gravity/slide disabled (or movement heavily damped in top-down equivalent).
   - Cling cooldown after release: 1.0 s.
2. Fireball
   - Adds ranged active ability.
   - Cooldown: 3.5 s.
   - Projectile speed: 600 px/s.
   - Damage: 28 base, scales with player damage modifiers.
   - Explosion radius: 42 px (optional splash).
3. Lifesteal Edge
   - Heal for 8% of melee damage dealt.
   - Cap healing per second: 10 HP/s.
4. Dash Burst
   - Dash distance: 170 px.
   - Dash cooldown: 4.0 s.
   - Dash grants 0.2 s invulnerability.
5. Arc Slash
   - Every 3rd melee attack emits a short-range arc projectile.
   - Arc damage: 70% of melee hit.

### Bad cards (at least these)

1. More Enemies
   - +30% enemies per non-boss wave (rounded up).
2. Spear Warriors
   - All Warriors switch from swords to spears.
   - Spear reach +45%, attack windup +20%, damage +15%.
3. Frenzied Pack
   - Enemy move speed +18%.
4. Thick Skins
   - Enemy HP +22%.
5. Venom Blades
   - Enemy hits apply DoT: 4 HP/s for 2.5 s (refreshable, not stackable).

## Card stacking rules

- Card effects are persistent for the entire run.
- Identical card duplicate behavior:
  - If repeat allowed later, use predefined stacking coefficients.
  - If repeat not allowed, reroll to another card.
- Use additive/multiplicative tags explicitly:
  - Additive example: +0.18 move speed
  - Multiplicative example: x1.22 enemy HP

## UI and readability requirements

## Required HUD elements

- Current HP and max HP.
- Current wave number.
- High score (best wave completed).
- Active good card count.
- Active bad card count.
- Boss wave indicator when wave % 5 == 0.

## Card choice UI

- On boss defeat, pause gameplay action.
- Show two side-by-side card panels:
  - left: good card (green/positive framing)
  - right: bad card (red/negative framing)
- Player must confirm both before unpausing.
- Show concise stat deltas on card text (exact numbers).

## Visual clarity standards

- Enemy telegraphs must be readable against arena floor.
- Boss telegraphs use stronger contrast than normal enemies.
- UI border area remains unobstructed by gameplay entities.

## Input and control assumptions

- Keyboard + mouse baseline:
  - Move: WASD
  - Melee attack: Left Mouse
  - Active power (e.g., Fireball): Right Mouse or Q
  - Dash (if unlocked): Space
- Gamepad support optional for first milestone.

## Failure, scoring, and progression

## Loss condition

- Player HP <= 0 at any time.
- Wave immediately fails and run ends.

## Scoring definition

- Score shown during run: current wave in progress.
- High score recorded as highest fully completed wave.
  - Example: die during wave 12 -> high score candidate is 11.

## Persistence requirements

- Save high score locally between sessions.
- If no save exists, high score defaults to 0.
- Save format can be minimal JSON with version key.

## Balancing constraints

- Time-to-kill for baseline wave 1 enemies:
  - 2-4 hits with fists, 1-3 with sword.
- Wave 10 should be clearly harder but survivable with average card luck.
- No single bad card should spike difficulty by more than approximately 30% alone.
- Combined bad cards are expected to create exponential pressure.

## Technical implementation guidance (engine-agnostic)

## Systems to implement as separate modules

- WaveManager
- EnemySpawner
- CombatResolver
- CardSystem
- BuffDebuffSystem
- BossController
- SaveSystem
- HUDController

## Data-driven definitions

- Store enemy stats, boss stats, and card definitions in data tables (JSON/scriptable objects).
- Card effects should be applied through generic stat modifier pipeline, not one-off hardcoded branches when possible.

## Determinism and testing support

- Use seeded RNG option for reproducible test runs.
- Log boss card rolls in debug mode.

## Minimum viable milestone checklist

1. Player movement + melee combat inside bordered arena.
2. At least 3 enemy archetypes with basic AI.
3. Wave progression with scaling enemy counts.
4. Boss every 5 waves.
5. Post-boss mandatory good+bad card reward screen.
6. At least 5 good cards and 5 bad cards functional.
7. Death ends run and records high score.
8. HUD displays HP, wave, and high score.

## Expansion roadmap (after MVP)

- Add additional good cards with synergy tags.
- Add additional bad cards targeting AI, hazards, and pacing.
- Add 2-3 boss variants rotating by bossIndex.
- Add biome themes while preserving rectangular arena rule.
- Add meta-progression only after core loop feels strong.

## Spirit lock (always reference this)

The game must always feel like: "A constrained arena survival climb where power and punishment grow together."
Player fantasy is becoming a manufactured superhero by surviving escalating waves and adapting to forced trade-offs.
Do not dilute this with open-world exploration, story-heavy interruptions, or unrelated side objectives.

Any new feature proposal should be checked against these spirit-lock questions:

1. Does it strengthen wave-based combat in a bounded arena?
2. Does it reinforce the good-card/bad-card tension?
3. Does it keep failure and high score central to replayability?
4. Does it preserve immediate readability and fast decision-making?

If answer is "no" for most questions, reject or redesign the feature.
