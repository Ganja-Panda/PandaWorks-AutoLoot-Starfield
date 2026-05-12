# PandaWorks AutoLoot (PWAL)

**PandaWorks AutoLoot** is a quality-of-life loot routing and inventory logistics framework for **Starfield**.

PWAL is not a cheat terminal, economy bypass, or instant-progression mod. It is designed to reduce repetitive looting and inventory management while preserving the core gameplay loop as much as possible.

It is the full framework rebuild of the original **Lazy Panda** auto-loot mod.

Where Lazy Panda proved the idea could work, PandaWorks AutoLoot rebuilds the system from the ground up using a cleaner, modular, performance-focused architecture.

---

## What PWAL Does

PWAL automatically detects lootable objects, processes them by category, and routes them to configurable destinations.

The goal is simple:

> Spend less time manually looting every corpse, crate, rock, and debris field, and more time actually playing the game.

PWAL can handle systems such as:

- containers
- corpses
- loose loot
- resource objects
- nonlethal Zoology harvest targets
- configurable category filters
- configurable loot destinations
- utility transfers between inventories
- terminal-based configuration
- aid-device quick actions
- PC hotkey / CGF command support where available  

Planned / experimental systems include:  

- ship debris support
- asteroid debris support
- space loot support

---

## What PWAL Is Not

PWAL is not intended to be a cheat mod.

There are already cheat terminals and cheat utility mods for players who want free credits, free XP, instant progression, or unrestricted reward sliders.

PWAL is built as a **QOL and logistics framework**.

That means:

- it removes repetitive friction
- it automates tedious looting
- it helps route items intelligently
- it protects players from known gameplay problems, such as contraband arrest loops
- it avoids turning every feature into a reward exploit

Some features may offer convenience rewards in the future, such as small asteroid XP or low-value Void salvage, but these will be intentionally balanced and will not replace merchants, skill progression, or normal gameplay systems.

---

## Core Philosophy

PWAL follows a simple rule:

> Quality of life removes friction. Cheating removes consequence.

For example, auto-unlock support may exist, but PWAL can also support skill-check behavior for players who want convenience without bypassing character investment.

The same applies to loot routing. The mod gives players broad control over where loot goes, but a few safety-critical categories are intentionally protected.

---

## Loot Filters

PWAL lets players choose what categories should be automatically looted.

Examples include:

- weapons
- armor
- ammo
- aid items
- chems
- food and drink
- resources
- manufactured resources
- organic resources
- containers
- corpses
- books
- dataslates
- skill magazines
- collectibles
- junk
- misc items
- planned / experimental space loot support
- nonlethal harvest resources

Filters determine **whether** PWAL should loot a category.

Destinations determine **where** that category goes.

---

## Loot Destinations

PWAL supports configurable destination routing.

A loot category can be routed to destinations such as:

- Player
- PandaWorks Storage
- Ship Cargo
- Lodge Safe
- The Void

Destination settings are category-based. This allows players to build their own logistics flow.

For example:

- resources can go to ship cargo
- collectibles can go to the Lodge Safe
- junk can go to PandaWorks Storage or The Void
- weapons and armor can go wherever the player prefers

Some categories are intentionally not exposed in the destination menu because they must stay safe.

---

## Fixed Routing Rules

A few categories are hard-routed for safety or progression reasons.

These are not normal destination options.

### Always Routed to Player

The following item types are intended to go directly to the player:

- credits
- digipicks
- Astra
- keycards
- landmark books
- skill magazines
- critical activator-based pickups
- quest/progression items when detected by the game

These items are treated as direct player acquisition items, not general storage loot.

### Contraband Safety Rule

Contraband always routes to **PandaWorks Storage** by default.

This is intentional.

Starfield’s contraband scan behavior can create an arrest loop if an auto-loot system silently moves contraband back to the player or ship cargo after the player has just been caught.

To prevent this, PWAL does not automatically send contraband to the player or ship.

Players who want to smuggle contraband must manually move it from PandaWorks Storage to their ship cargo or personal inventory.

---

## Ship Cargo Availability

Ship cargo is only available after the player has access to an active home ship, such as after receiving the Frontier.

Before that point:

- Ship Cargo cannot be opened
- items should not be transferred into ship cargo
- ship transfer commands may fail safely
- loot routed to ship cargo may be redirected to PandaWorks Storage until a valid ship exists

This protects early-game saves from broken or nonexistent ship references.

---

## The Void

The Void is planned as a disposal destination.

Items routed to The Void are destroyed instead of stored.

The Void is intended as a cleanup and salvage feature, not a replacement for merchants.

If credit salvage is added, it will be a small percentage of the item’s value with a minimum payout, such as 1 credit. It will not be tuned to outperform selling items normally.

The Void is for convenience, not infinite money.

---

## Terminal Configuration

PWAL uses an in-game terminal interface as its main configuration system.

The terminal is planned around four major areas:

- Loot Filters
- Loot Destinations
- Settings
- Utilities

### Loot Filters Menu

Controls what categories are automatically looted.

### Loot Destinations Menu

Controls where configurable categories are sent.

### Settings Menu

Controls general behavior such as looting enabled/disabled, logging, scan radius behavior, auto-unlock settings, and other framework options.

### Utilities Menu

Provides inventory and transfer actions, such as:

- open PandaWorks Storage
- open Lodge Safe
- open Ship Cargo
- move resources to ship
- move valuables to player
- move all from PandaWorks to ship
- move all from ship to PandaWorks
- move all from Lodge Safe to PandaWorks
- move all from Lodge Safe to ship

---

## Aid Device

PWAL will include a single aid/utility device for quick access.

The aid device is intended for console-friendly use and for players who do not want to open the full terminal every time.

Planned aid-device actions include:

- enable or disable looting
- enable or disable logging
- open PandaWorks Storage
- open Lodge Safe
- open Ship Cargo
- access quick transfer actions

The full terminal remains the main configuration tool. The aid device is the quick control panel.

---

## PC Hotkey / CGF Support

PC players may be able to bind certain PWAL commands using console command function calls.

PWAL will expose a small public command façade for hotkey use.

The hotkey-facing script will not contain the actual logic. It will only forward commands to the proper PWAL services.

Example command categories may include:

- open terminal
- open PandaWorks Storage
- open Lodge Safe
- open Ship Cargo
- toggle looting
- move resources to ship
- move valuables to player
- move all from ship to PandaWorks

Console versions will use the aid device instead.

---

## Performance Design

PWAL is designed around distributed, budgeted scanning.

Instead of one giant script trying to do everything, PWAL uses multiple MagicEffect-based workers configured through the Creation Kit.

Each effect handles a specific type of loot or behavior.

The system is designed around:

- distributed MagicEffect workers
- category-specific scan filters
- staggered timer starts
- internal processing budgets
- shared processor services
- destination resolution
- controlled transfer behavior

The goal is to avoid Papyrus VM stalls and reduce the risk of large script spikes.

Raw scan timing is not intended to be exposed directly to players. Timing and budgets are treated as internal engineering values, not user-facing sliders.

Future versions may include curated performance profiles, such as:

- Lazy Panda
- Active Panda
- Stoned Panda

But these profiles will use safe internal values rather than unrestricted timing controls.

---

## Planned Profiles

Profiles are planned for a future release.

### Lazy Panda

Lowest workload profile.

Designed for minimal automation and conservative behavior.

### Active Panda

Recommended balanced profile.

Enables practical looting categories and common quality-of-life behavior.

### Stoned Panda

Maximum shiny-object mode.

Enables most configurable categories and performs the most aggressive looting behavior within safe limits.

The panda likes shiny things. This may or may not be wise.

---

## Nonlethal Harvest Support

PWAL includes support for Starfield’s native nonlethal Zoology harvest behavior.

This is not a custom fake harvest system.

PWAL uses the game’s own nonlethal harvest condition logic and harvest effect behavior, then integrates it into the same framework used by normal looting.

This allows harvestable organic targets to be processed through PWAL’s scanner and processor architecture without needing a separate standalone harvest script.

---

## Framework Architecture

PWAL is built as a modular framework.

Major systems include:

- LootEffect workers
- LootScanner
- LootProcessor
- ContainerProcessor
- CorpseProcessor
- HarvestProcessor
- DestinationResolver
- CommandService
- TransferActionService
- Terminal menu scripts
- Aid device input script
- Daemon / CGF command façade

The design goal is to keep each script focused.

Loot workers scan.

Processors process.

The destination resolver resolves.

Command services execute player actions.

Terminal and aid-device scripts act as input surfaces only.

This keeps the system easier to debug, easier to expand, and less likely to become one giant script trying to do everything.

---

## Known Limitations

- Space loot support is experimental.
- Ship Cargo requires an active home ship.
- Terminal UI token refresh behavior is being rebuilt from the Lazy Panda system and may change during testing.
- Performance profiles are planned but not currently exposed.

---

## Development Status

PWAL is currently under active development.

This repository reflects ongoing framework work and may not represent a final release build.

Features and behavior may change before release.

Current major development areas include:

- terminal menu framework
- destination configuration menus
- aid-device quick actions
- transfer service implementation
- hotkey/CGF façade
- framework stability testing
- console testing
- performance tuning

---

## Distribution

PWAL will only be officially available through:

- Bethesda Creations / Creation Club
- Nexus Mods
- this GitHub repository

Any other distribution is unauthorized.

---

## License

Copyright (c) 2026 PandaWorks Studio. All rights reserved.

See the LICENSE file for details.
