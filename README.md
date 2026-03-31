# Manufactured Superhero

A wave-based arena survival game where you become stronger and the world becomes harsher at the same time.

## Game concept

You fight inside a fixed rectangular arena that sits inside a visible UI border.
Every 5th wave is a boss wave.
After each boss kill, you are forced to take:

- 1 random good card (power increase)
- 1 random bad card (difficulty increase)

Runs end when you fail a wave. Your score is your highest completed wave.

## Source of truth

The full design specification lives in:

- `docs/Game Plan.md`

Always use that document as the canonical direction for mechanics, scaling, UI constraints, and progression rules.

## Core loop

1. Start wave with base loadout (fists or sword).
2. Defeat all enemies.
3. On boss waves, defeat boss.
4. Receive and accept one good + one bad card.
5. Continue until death.
6. Save/update high score.

## Current project status

This repository currently contains design documentation and setup files.
Gameplay code and engine scaffolding are expected to be added next.

## Suggested next implementation milestones

1. Create game project scaffold (engine/runtime of choice).
2. Implement arena bounds + movement + melee combat.
3. Implement wave spawning and scaling.
4. Implement boss cadence (every 5 waves).
5. Implement card reward UI and card effect system.
6. Implement HUD and high score persistence.

## Repository structure

- `docs/` - design and planning documents
  - `Game Plan.md` - detailed spec and spirit-lock constraints

## Development notes

- Keep gameplay deterministic where possible (seeded RNG support helps test balancing).
- Keep card effects data-driven to avoid hardcoding one-off logic.
- Preserve the game spirit: power growth and punishment growth must stay paired.
