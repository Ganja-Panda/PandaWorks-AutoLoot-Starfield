# PandaWorks AutoLoot for Starfield

**PandaWorks AutoLoot** (PWAL) is a configurable loot-routing and inventory-logistics framework for **Starfield**. It reduces repetitive looting while letting the player control which supported loot is collected and where it goes.

PWAL is the framework rebuild and successor to **Lazy Panda**. Creation Kit records configure its independent loot effects; focused Papyrus services scan, validate, process, and route the results.

## Current Status

The current source target is **1.2.1**.

Ground looting, category filtering, destination routing, terminal configuration, Gameplay Options integration, transfer utilities, harvesting, and supported space salvage are implemented. PWAL remains actively maintained, but these are current features rather than planned or experimental systems.

## What PWAL Does

PWAL can process supported loose objects, containers, corpses, harvest targets, and configured space-salvage sources. Before moving loot, it applies source, location, ownership, quest-item, protected-storage, and runtime checks appropriate to that processing path.

Core features include:

- configurable loot filters and leaf-category destinations;
- separate handling for loose loot, containers, corpses, and harvesting;
- filtered container and corpse inventory transfers;
- optional container unlocking with key, digipick, and Security-skill checks;
- configurable stealing behavior for supported sources;
- PandaWorks Inventory, Player, home-ship cargo, and Lodge Safe routing;
- protected player storage and player-owned ships;
- asteroid/mineral deposits, generated space cargo, and hostile destroyed-ship salvage;
- management terminal, portable Utility Device, and native Gameplay Options integration;
- storage-transfer utilities and public PC Call Global Function commands;
- optional Gravitic Stowage Matrix inventory-weight profiles.

PWAL is a quality-of-life system, not a cheat terminal or instant-progression tool. It removes friction; it is not meant to remove every consequence.

## Getting Started

1. Install the complete current release and enable its plugin.
2. Load a save and wait for PWAL to finish initialization.
3. If needed, enable the handheld management terminal through Gameplay Options.
4. Open the terminal from the **Weapons** inventory category.
5. Enable the loot filters you want and choose destinations.
6. Review location, unlocking, stealing, and radius settings.
7. Enable looting and test one simple category first.

On a new install, looting and all loot filters are off. The default destination is Player. Location permissions, auto-unlock, corpse removal, stealing, hostile stealing, and logging also default off.

See [Getting Started](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Getting-Started) and [Quick Start](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Quick-Start) for the complete first-use flow.

## Loot Categories

PWAL provides high-level groups with more specific child filters:

- weapons: pistols, rifles, shotguns, heavy, melee, and throwables;
- armor: apparel, packs, helmets, and spacesuits;
- consumables: aid, chems, drinks, and food;
- lore: dataslates, landmark books, and skill magazines;
- collectibles: action figures, antiques/toys, creature eggs, plushies, and snow globes;
- miscellaneous: ammo, contraband, crafting items, currency, junk, keycards, schematics, upgrade modules, and other miscellaneous items;
- resources: inorganic, manufactured, organic, nonlethal harvest, and X-Tech groups;
- source filters for supported containers, corpses, ship interiors, and space salvage.

Container/corpse source filters decide which references may be inspected. Item filters decide which matching contents may be transferred. Categories and destinations are separate controls.

See [Loot Categories](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Loot-Categories).

## Destinations

Normal ground loot can be configured for:

- Player;
- PandaWorks Inventory;
- Player Ship Cargo through the current home-ship reference;
- Lodge Safe.

If PandaWorks Inventory, ship cargo, or Lodge Safe is selected but unavailable, normal destination resolution falls back to Player.

Some groups override normal routing. Landmark books, skill magazines, action figures, snow globes, currency, keycards, schematics, upgrade modules, and X-Tech resources are forced to Player. **Contraband is forced to the Lodge Safe.**

The terminal exposes a fifth destination code, The Void, but current processors do not implement reliable deletion when it resolves to no destination reference. PWAL therefore does not advertise The Void as a working disposal feature in this release.

See [Destinations](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Destinations) for routing order, overrides, fallbacks, and the current Void limitation.

## Containers and Corpses

Containers and corpses are separate processing paths.

Supported containers are validated, unlocked when allowed, and filtered through configured item lists. Matching groups resolve their own destinations; PWAL does not blindly move the entire container inventory. Owned containers are rejected when stealing is disabled. Player, PandaWorks, Lodge, and protected ship-storage sources are not treated as ordinary loot containers.

Only dead actors enter corpse processing. Current corpse looting is filtered by configured item lists and destinations, and successfully processed corpses are marked to prevent repeat work. Optional corpse removal only disables a corpse when the corpse reference is not a quest item and no inventory remains.

## Stealing and Ownership

With stealing disabled, PWAL rejects owned loose objects and owned containers under the current validation rules. Dead actors are handled by the separate corpse path.

When stealing is enabled and hostile stealing is off, the loose-item path changes the loose reference's ownership before transfer. This laundering step is limited to loose loot and does **not** guarantee immunity from every crime, ownership, or contraband system. Hostile stealing leaves ownership intact. Turning stealing off also turns hostile stealing off.

See [Core Concepts](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Core-Concepts) for the detailed rules.

## Space Salvage

Space salvage is implemented through dedicated candidate and processor paths. Current supported systems include:

- configured asteroid/mineral deposit containers;
- configured generated space-cargo containers;
- hostile ships watched during player-ship combat and submitted after destruction.

Accepted space-salvage sources transfer their complete inventory to the current home-ship cargo target. They do not use normal ground category destinations. A valid home ship is required; unavailable or failed candidates are retried by the space pipeline before being discarded from its processing inbox.

### Player Ship Protection

PWAL distinguishes hostile salvage from player property. Ship-debris detection rejects the current player ship, the home ship, ships carrying the player-ship keyword, and every ship reported as player-owned. Ground validation also protects the player/home ship references and related ship inventory from inappropriate source processing.

See [Space Salvage](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Space-Salvage) for supported sources and processing details.

## Management Terminal

The **PandaWorks AutoLoot Management Terminal** is the detailed configuration interface. Use it for:

- loot filters and categories;
- default and category destinations;
- interior, city, and wilderness radii;
- Lodge, outpost, player-home, and ship-interior permissions;
- unlocking and corpse-removal settings;
- stealing and hostile-stealing settings;
- Always Loot settings;
- inventory access and transfer utilities.

The terminal is a weapon-category inventory item. Gameplay Options can add or remove the item, but the terminal itself is opened from inventory.

## Utility Device

The portable **PandaWorks Utility Device** opens the smaller utilities terminal. It provides quick access to:

- the looting toggle;
- PandaWorks Inventory, Lodge Safe, and home-ship cargo;
- transfers between supported storage locations;
- resource-to-ship and valuables-to-player transfers.

The Utility Device is not the complete configuration interface. Logging is available through the public CGF command rather than the current Utility Device menu.

See [Utility Device](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Utility-Device).

## Gameplay Options

PWAL's native Gameplay Options integration provides high-level controls rather than duplicating the full management terminal. It can:

- enable or disable all standard categories;
- enable or disable all Always Loot entries;
- apply a Quick Start destination or preserve existing destinations with Default;
- add or remove the management terminal and Utility Device items;
- enable or disable looting;
- configure the Gravitic Stowage Matrix.

The **Gravitic Stowage Matrix** manages one Gravitic Chronomark with Disabled, 25%, 50%, 75%, and Weightless profiles across supported inventory groups. Disabling the Matrix removes the Chronomark without disabling PWAL.

See [Terminal Menus and Gameplay Options](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Terminal-Menus).

## Call Global Function Support

PWAL exposes public no-argument CGF commands through `PWAL:Daemon` for hotkeys, console command runners, bat files, and external command bindings.

Public commands are routed through PWAL's command service, with each command performing the runtime and reference checks required for that action. Available commands cover terminal access, looting/logging/stealing toggles, inventory access, and supported storage transfers.

See [Call Global Functions](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Call-Global-Functions) for exact command names and compatibility aliases.

## Official Content Integration

The current plugin directly integrates its configured official-content records and has hard master references to `Starfield.esm`, `sfbgs00d.esm`, `SFBGS004.esm`, `sfbgs007.esm`, `SFBGS008.esm`, `SFBGS047.esm`, `sfbgs003.esm`, and `SFBGS006.esm`.

Those files must be present for the current plugin to load. Current evidence does not show separate PWAL patches for these integrated records. See [Installation](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Installation) for the authoritative dependency list.

## Documentation

The [PWAL GitHub Wiki](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki) contains the detailed documentation:

- [Getting Started](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Getting-Started)
- [Installation](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Installation)
- [Quick Start](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Quick-Start)
- [Core Concepts](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Core-Concepts)
- [Loot Categories](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Loot-Categories)
- [Destinations](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Destinations)
- [Space Salvage](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Space-Salvage)
- [Terminal Menus and Gameplay Options](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Terminal-Menus)
- [Utility Device](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Utility-Device)
- [Call Global Functions](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Call-Global-Functions)
- [Troubleshooting](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Troubleshooting)
- [Support](https://github.com/Ganja-Panda/PandaWorks-AutoLoot-Starfield/wiki/Support)

Read the wiki before reporting a bug. The answer may already be there, sitting quietly, judging everyone.

## Support

Support, bug reports, testing feedback, and discussion are handled through the PandaWorks Discord:

https://discord.gg/aGJhkYb4

A useful report includes the PWAL and Starfield versions, platform, installation method, exact source/item, relevant filters and destinations, location/ownership/lock state, repeatable steps, and useful lines from the `PandaWorks AutoLoot` user log.

“Mod broken” is not a bug report. That is a distress signal from a fog machine.

## Distribution

Obtain PWAL only through release links published or authorized by PandaWorks Studios / Ganja Panda. Reuploads, unofficial redistribution, ports, and reuse of project content are not authorized.

## License

Copyright (c) 2026 PandaWorks Studios / Ganja Panda. All rights reserved.

PandaWorks AutoLoot for Starfield is proprietary mod content. Unauthorized redistribution, reuse, modification, or porting is not permitted. See [LICENSE.md](LICENSE.md) for details.
