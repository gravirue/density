# Roblox LocalScript Tester

A Studio-only Roblox LocalScript test harness with three movement modes:

- **Orbit** — unanchored BaseParts orbit around the player.
- **Snake** — parts form a long animated wave-like noodle.
- **Wings** — parts form two flapping wings attached visually around the player.

The script scans all unanchored `BasePart` objects in `Workspace` and excludes the local player's character.

## Installation

1. Open your Roblox place in Roblox Studio.
2. Create a new **LocalScript** under:

   `StarterPlayer > StarterPlayerScripts`

3. Copy the contents of `LocalScript.lua` into the LocalScript.
4. Start a Studio play test.

The script intentionally stops immediately outside Roblox Studio.

## Controls

### Main menu

- **Orbit radius** — enter an exact orbit radius.
- **Apply** — apply the entered orbit radius.
- **Reset** — reset the orbit radius to `20`.
- `-` and `+` — decrease or increase the orbit radius.
- **Rescan Parts** — rescan Workspace for unanchored BaseParts.
- **Modes** — open or close the mode menu.

### Modes menu

- **Orbit** — select it again to disable it.
- **Snake** — select it again to disable it.
- **Wings** — select it again to disable it.
- **Emergency Stop** — immediately disables the active mode.

### Snake settings

- **Width** — controls the wave's sideways amplitude.
- **Size** — controls the total length of the noodle.

Keyboard shortcuts:

- `[` decreases the orbit radius.
- `]` increases the orbit radius.
- `M` opens or closes the modes menu.

## Important Roblox behavior

This is a client-side Studio test harness. In a live multiplayer server, client-side movement of server-owned physics parts may not replicate or may be overridden by the server. For a production multiplayer feature in a place you own, move the logic into a server Script and validate any client requests.