# MacroPilot

MacroPilot is an open, local-first control center for inexpensive macropads.
It is designed to make generic HID macro keyboards useful on macOS and Linux
without vendor software or account lock-in.

The first verified adapter supports a wired six-key/one-knob pad (`1189:8890`)
with a compact vendor configuration protocol. USB IDs can be shared across
firmware revisions, so this is a verified reference device rather than a
promise that every pad with that ID will behave the same way.
The initial kit has an **AI Workbench** profile, but the architecture is
general-purpose: one mapping can serve coding agents, accessibility workflows,
media, editing, streaming, and ordinary desktop shortcuts.

## What exists today

- A verified neutral `F13`–`F21` mapping for the reference six-key/one-knob
  pad, plus an experimental CH57x mapping.
- A portable JSON profile format with action names and safety levels.
- A dependency-free Node command-line profile inspector that runs on macOS and Linux.
- A documented boundary between configuration writes and host-side actions.
- A narrow, reviewable raw-USB mapper for the first six-key/one-knob pad.

## Safety model

Hardware configuration writes are never implicit. The default profile marks
actions such as **Send** and **New** as confirmation-requiring so a future host
app can make accidental commits of intent harder.

## Try the kit

```sh
npm run validate
npm run inspect
npm test
```

## Phase 1: macOS companion

`MacroPilot` is a local menu-bar companion for a neutral Control-Option-A
through I layout.
It listens for the macropad globally and gives the controls ordinary Mac
meaning: summon Codex, capture clipboard context, stop, guarded send/new-task
actions, and profile cycling. It does not use an API key or transmit your
context anywhere.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run MacroPilot
```

This development launch requires the full Xcode app. A packaged `.app` is the
next distribution step, so people will not need developer tools to use it.

The first time you use an action that sends a shortcut, choose **Check
Accessibility Permission** from the `MP` menu-bar item and approve it in macOS
System Settings. `Send` and `New Task` require a second press within three
seconds. For Voice, configure ChatGPT desktop's Voice shortcut as
Control-Option-B; MacroPilot sends that exact chord and does not need its own
microphone permission.

Default actions are Control-Option-A summon, B voice, C capture context, D
stop, E send, F new task, G/I profile previous/next, and H cycle profile.

## Reference hardware mapping

The `profiles/ch57x-8890-neutral-controls.yaml` file is compatible with
[ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool). Review
and validate it before uploading; an upload changes the connected macropad.
That CH57x path is separate from the verified compact-protocol adapter. See
[the six-key/one-knob adapter guide](docs/sikai-6key-adapter.md) for the
reference pad in this project.

## Roadmap

1. macOS menu-bar companion: global input, profiles, voice/dictation, and
   accessibility permission flow.
2. Explicit CH57x backup/validate/upload workflow.
3. Linux daemon and desktop integration.
4. More HID and QMK/VIA adapters.
5. Optional LED feedback where the device protocol supports it.

MacroPilot is an independent community project and is not affiliated with or
endorsed by any AI provider or macropad vendor.

See [NOTICE.md](NOTICE.md) for the open-source hardware-adapter attribution.
