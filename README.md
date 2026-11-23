# PZ-ImperialUnits

A Project Zomboid (Build 42) mod that shows gallons and pounds in place of the game's litres, millilitres and kilograms.

**Work in progress (0.1.0). Not tested in the game yet, not on the Workshop.**

## What it changes
- Feeding trough water, in the trough's window and in its tooltip: gallons.
- Animal zone window, "Available Water": gallons.
- Animal weight: pounds (ounces for animals under 1 kg).

## What it can't change
The amounts on a water bottle's tooltip and the pour-liquid panel are drawn by the game's Java code, which a mod can't reach. Temperature already has a game option (Options, UI, Temperature Display).

## How it works
`IU_Hooks.lua` wraps the game's window functions, so the game's own code still runs. The one exception is the trough tooltip, `FeedingTrough/CFeedingTroughSystem.lua`, which is replaced as a whole file. After a game update run `tools/check_vanilla.sh` to see if the original changed.

## Tests
```
python3 -m venv .venv && .venv/bin/pip install "lupa==2.8"
.venv/bin/python tests/run_tests.py ImperialUnits/Contents/mods/ImperialUnits/42.21/media/lua
```
