# PandaWorks AutoLoot for Starfield

**PandaWorks AutoLoot** is a quality-of-life loot routing and inventory logistics framework for **Starfield**.

PWAL is designed to reduce repetitive looting and inventory management while still giving the player control over what gets looted and where it goes.

It is the framework rebuild and successor to **Lazy Panda**.

Lazy Panda proved the idea worked.

PandaWorks AutoLoot turns it into a larger, cleaner, more configurable system.

---

## Current Status

PWAL is live and operational.

Core looting, filtering, destination routing, and plugin support are working. Current work is focused on optimization, bug fixes, menu cleanup, and edge-case handling discovered through testing on PC and console.

The framework is stable enough for public use, but still under active refinement.

---

## What PWAL Does

PWAL can automatically detect supported loot, filter it by category, and route it to configured destinations.

The goal is simple:

Spend less time manually looting every corpse, crate, rock, and debris field, and more time actually playing the game.

PWAL currently supports or is being built around systems such as:

- Containers
- Corpses
- Loose loot
- Resource objects
- Nonlethal Zoology harvest targets
- Configurable loot categories
- Configurable loot destinations
- PandaWorks Inventory
- Player inventory routing
- Player Ship Cargo routing
- Lodge Safe routing
- Utility terminal access
- Portable Utility Device access
- Transfer utilities
- Terminal-based configuration
- PC Call Global Function command support

Planned or experimental systems may include:

- Ship debris support
- Asteroid debris support
- Expanded space loot support

---

## What PWAL Is Not

PWAL is not a cheat terminal.

PWAL is not an economy bypass.

PWAL is not an instant-progression mod.

There are already cheat terminals and cheat utility mods for players who want free credits, free XP, unrestricted reward sliders, or instant unlocks.

PWAL is a **quality-of-life and logistics framework**.

That means it is designed to:

- Reduce repetitive looting
- Automate tedious inventory cleanup
- Route items intelligently
- Protect players from known gameplay problems
- Keep configuration in the player’s hands where appropriate
- Avoid turning every feature into a reward exploit

PWAL removes friction.

It is not supposed to remove consequence.

---

## Basic Use

After installing PWAL:

1. Open your inventory.
2. Go to the **Weapons** section.
3. Use the **PandaWorks AutoLoot Terminal**.
4. Enable the loot categories you want.
5. Set destinations for configurable loot.
6. Enable looting.
7. Test with a small amount of loot first.

If looting is disabled, PWAL will not loot.

If a category is disabled, PWAL will not loot that category.

That is not a bug.

That is the panda obeying instructions.

---

## Main Terminal

The **PandaWorks AutoLoot Terminal** is the main configuration interface.

It is found in the **Weapons** section of the player inventory.

Use it for:

- Loot category setup
- Destination setup
- General settings
- Always Loot settings
- Utility menus
- Inventory access
- Transfer tools

If you are setting up PWAL for the first time, use the main terminal.

---

## Utility Device

PWAL also includes a **PandaWorks Utility Device**.

The Utility Device opens the utility terminal from the player inventory.

It is meant for quick access to common tools such as:

- Open PandaWorks Inventory
- Open Lodge Safe
- Open Player Ship Cargo
- Transfer utilities
- Toggle looting
- Toggle logging

The Utility Device is not the main setup terminal.

Use the main terminal for full configuration.

Use the Utility Device for quick access during gameplay.

---

## Loot Categories

Loot categories control what PWAL is allowed to loot.

Examples include:

- Weapons
- Armor
- Ammo
- Aid
- Chems
- Food
- Drinks
- Books
- Dataslates
- Resources
- Collectibles
- Junk
- Containers
- Corpses
- Harvestables

Categories decide whether PWAL can loot something.

Destinations decide where the loot goes.

Do not confuse the two.

---

## Destinations

PWAL can route supported configurable loot to several destinations:

- Player
- PandaWorks Inventory
- Player Ship Cargo
- Lodge Safe
- The Void, where available

Some item groups are forced to specific destinations for safety, progression, or gameplay reasons.

Not every backend rule is exposed to the player.

Some knobs should not be handed to people who will immediately turn them sideways and complain the machine screams.

---

## Forced Routing Rules

Some items are not treated like normal storage loot.

These items go directly to the player:

- Credits
- Keycards
- Skill magazines
- Landmark books
- Collectibles
- Certain activator-based pickups
- Quest/progression items when detected by the game

This is intentional.

These items are tied to direct acquisition, progression, unlocks, or player clarity.

Do not report this as a destination bug.

---

## Contraband

Contraband is special.

By default, contraband routes to **PandaWorks Inventory**.

This is intentional.

Starfield’s contraband scan system can create stupid arrest-loop problems if automation moves contraband into the wrong place at the wrong time.

PWAL keeps contraband out of normal player/ship routing unless the framework explicitly allows safe handling.

If you want to smuggle contraband, move it manually when you are ready.

The panda is trying to keep you out of space jail.

Mostly.

---

## Ship Cargo

Player Ship Cargo requires a valid player home ship.

If the player does not have a valid home ship yet, ship cargo tools may fail safely or redirect depending on current framework behavior.

PWAL cannot store loot in a ship the game has not properly assigned.

That is Starfield’s problem.

PWAL just has to survive it.

---

## The Void

The Void is a disposal-style destination.

Items sent to The Void are not stored normally.

The Void is intended for cleanup and possible salvage-style behavior.

It is not intended to replace vendors or become a free money printer.

If you send something to The Void, do not expect to get it back.

The Void eats.

The Void does not apologize.

---

## Performance Design

PWAL is designed around distributed, budgeted scanning.

Instead of one giant script trying to do everything, PWAL uses focused systems with separated responsibilities.

Major concepts include:

- MagicEffect-driven workers
- Category-specific scanning
- Validation services
- Processor services
- Destination resolution
- Transfer services
- Terminal menu scripts
- Command services
- Utility access points

The goal is to keep each script focused.

Scanners scan.

Validators validate.

Processors process.

Destination systems route.

Terminal and utility scripts act as input surfaces.

This keeps the system easier to debug, easier to expand, and less likely to become one giant cursed script dragging itself across the floor.

---

## Call Global Function Support

PWAL exposes public Call Global Function commands through `PWAL:Daemon`.

These commands are mainly for:

- Hotkeys
- Console command runners
- Bat files
- External command bindings
- Advanced user automation

Normal users should use the in-game terminal menus unless they specifically want external command bindings.

See the wiki page:

[Call Global Functions](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Call-Global-Functions)

---

## Documentation

Full documentation is available in the GitHub Wiki:

[PWAL Wiki Home](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki)

Recommended pages:

- [Getting Started](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Getting-Started)
- [Installation](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Installation)
- [Quick Start](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Quick-Start)
- [Core Concepts](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Core-Concepts)
- [Utility Device](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Utility-Device)
- [Terminal Menus](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Terminal-Menus)
- [Destinations](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Destinations)
- [Loot Categories](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Loot-Categories)
- [Troubleshooting](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Troubleshooting)
- [Support](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Support)

Read the wiki before reporting bugs.

The answer may already be there, sitting quietly, judging everyone.

---

## Support

Support, bug reports, testing feedback, and general discussion are handled through the PandaWorks Discord.

Join here:

https://discord.gg/aGJhkYb4

When reporting bugs, include useful information:

- PWAL version
- Starfield version
- Mod manager used
- What you expected to happen
- What actually happened
- Which category was involved
- Which destination was selected
- Where you were in-game
- Whether the issue repeats
- Any useful log output

“Mod broken” is not a bug report.

That is a distress signal from a fog machine.

---

## Distribution

PWAL is officially distributed through:

- GitHub
- Nexus Mods, when available
- Bethesda Creations / Creation Club, when available

Any other distribution is unauthorized.

Do not reupload this mod.

Do not redistribute it.

Do not port it.

Do not reuse its content without explicit permission.

---

## License

Copyright (c) 2026 PandaWorks Studios / Ganja Panda. All rights reserved.

PandaWorks AutoLoot for Starfield is proprietary mod content.

Unauthorized redistribution, reuse, modification, or porting of PandaWorks AutoLoot is not permitted.

See the LICENSE file for details.
