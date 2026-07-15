# Clear Da Boom

A client-side [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8) mod that removes the explosion **visual cloud** (smoke/flash/debris) from the Ogryn's explosives, while leaving the explosion **sound** and **damage** completely unchanged.

## What it clears

Three independent toggles in the mod settings menu (all on by default):

- **Rumbler** — the Mk II grenade launcher's detonation cloud.
- **Grenadier Gauntlet** — the underslung grenade's detonation cloud.
- **Ogryn grenades** — the thrown Frag and Box grenades' detonation clouds.

Sound, damage, radius, and stagger are untouched. Other classes' grenades (Veteran frag/krak, etc.) are unaffected, even where they share a particle effect with the Ogryn's.

## How it works

At load it caches, then blanks, the `vfx`/`scalable_vfx` fields on the six Ogryn explosion templates. No hooks; the change is applied per-detonation by the engine, so toggling a setting takes effect immediately with no restart.

## Install

Extract into your Darktide `mods` folder and add `Clear Da Boom` to `mod_load_order.txt` (after `dmf`).
