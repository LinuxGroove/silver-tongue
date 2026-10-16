# Silver Tongue

*Talk your way in. Everyone can hear you.*

A co-op con game where the characters listen. You and your crew talk out
loud, the people in the building hear what you say, and a guard who is
told a good enough story opens the door. For Linux PCs and handhelds, made
with Godot 4. Part of [LinuxGroove Games](https://linuxgroove.com); the
concept is idea 23 in
[game-ideas](https://github.com/LinuxGroove/game-ideas/blob/main/ideas/23-silver-tongue.md).

Hearing, the characters' brains and their voices all run on your own
machine, through [Lemonade Server](https://lemonade-server.ai): nothing you
say leaves it, and nobody pays by the word.

## Where it is

This is **M0, the service door**: one room, one guard, one door, built to
prove the voice stack before any of the Hotel Meridian is built. You stand
in the Meridian's service corridor. Marcus from Halberd Security stands at
the service door. Talk him into opening it.

- **Hold V (or the right trigger) and talk.** Let go and he thinks about
  it. Hold Shift to whisper, Alt to shout, and walk closer if he can't hear
  you. Press T to type a line instead.
- Marcus hears what reaches him: a whisper from a step away, a normal
  voice from a few steps, a shout from the far end of the corridor, with
  words dropping out in between.
- He answers out loud, in his own voice, with a mouth that moves, and can
  ask reception, ask for your badge, let you through or radio security.
  The rules decide what he is allowed to do; the model only talks.
- The readout at the bottom shows how long each turn took to hear, think
  and speak, how much of the prompt the model's cache reused, and whether
  the reply followed the schema. That is what M0 is for; see
  [docs/m0.md](docs/m0.md) for the measurements to make.
- With no model (AI off, or no Lemonade), Marcus falls back to scripted
  lines, so the door still plays.

## Running it

From source, with Godot 4.7:

```sh
godot --headless --path . --import && godot --headless --path . --import
godot --path .                     # the title
godot --path . -- --door           # straight to the service door
godot --path . -- --door --text    # typing your lines
```

The game starts Lemonade itself when the embedded one is there (the snap
bundles it). The first time you play, a setup screen downloads Marcus's
three models (his brain, his ears and his voice) with a progress bar for
each, before you reach the door; after that he's ready in seconds. From source,
point it at a Lemonade you run yourself:

```sh
godot --path . -- --door --set=ai/mode=external --set=ai/external_url=http://localhost:8000/api/v1
```

The snap is not published yet.

## Status

M0 in progress. The milestones after it (the Meridian's first job, the
campaign, the city online, two crews) are in the idea file.

## Credits and licence

Made by Drew, Kaden and Ken VanDine, the LinuxGroove team. The code is MIT
(see [LICENSE](LICENSE)); the art, fonts and software it builds on are
listed in [CREDITS.md](CREDITS.md).
