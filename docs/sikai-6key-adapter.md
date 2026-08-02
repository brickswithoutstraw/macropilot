# SIKAI-style six-key / one-knob adapter

Status: **verified reference adapter** — the narrow F13–F21 layout below was
successfully written to a wired 3×2-key, single-knob pad.

The physical pad used for this adapter advertises USB vendor/product ID
`1189:8890`. It presents several ordinary HID functions to macOS (keyboard and
pointer/scroll). Those IDs are shared by multiple firmware revisions, so an ID
match alone is not a compatibility guarantee.

## Protocol boundary

The pad accepts 65-byte HID output reports: report ID `3` plus a 64-byte
payload. Each simple keyboard binding is stored as two compact records: a
modifier record and a HID-key record. `AA AA` commits a complete batch.

The protocol was cross-checked against public reverse-engineering research;
see [ATTRIBUTION.md](../ATTRIBUTION.md). MacroPilot does not bundle vendor
software or its executable.

The vendor program also exposes commands with these payload beginnings:

| Purpose | Payload beginning |
| --- | --- |
| Save key bindings | `FE …` |
| Commit bindings | `AA AA` |
| Save LED settings | `AA A1` |
| Change active layer | `A1 <layer>` |

This differs from an earlier generic CH57x uploader, which assumes a single
USB control endpoint. Do not use that uploader for this adapter.

## Safe diagnostic

Build the macOS probe:

```sh
clang -framework IOKit -framework CoreFoundation \
  tools/macropilot-hid-probe.c -o tools/macropilot-hid-probe
```

Then list the pad's HID functions:

```sh
tools/macropilot-hid-probe
```

`--version-query` sends only the vendor application's all-zero version query
over the report IDs it probes. It does not assign keys, alter layers, or write
the flash/LED commands above.

If macOS reports that the keyboard is already in use, use the explicit
`--seize-version-query` option instead. It temporarily takes the pad away from
the system keyboard service for the few milliseconds needed to send the same
non-mutating query, then releases it; do not press the pad during that probe.

For a read-only view of raw USB interfaces and endpoints (the path used by the
cross-platform adapter), build and run:

```sh
clang $(pkg-config --cflags --libs libusb-1.0) \
  tools/macropilot-usb-inspect.c -o tools/macropilot-usb-inspect
tools/macropilot-usb-inspect
```

The current device has configuration interface `1` and interrupt OUT endpoint
`0x02`. MacroPilot's `macropilot-usb-probe` uses only that interface and sends
the vendor program's all-zero version request through report IDs `0`, `2`, and
`3`; it sends no configuration command.

## Build and inspect the mapper

Build the mapper:

```sh
clang $(pkg-config --cflags --libs libusb-1.0) \
  tools/macropilot-sikai-map.c -o tools/macropilot-sikai-map
```

Inspect the packets without connecting to the device:

```sh
tools/macropilot-sikai-map --preview-macropilot-layout
```

An intentionally visible smoke test remains available as `--preview-key1-a` /
`--apply-key1-a`; firmware key ID 1 is physical **bottom-left** on the
reference pad.

The vendor software's active (non-legacy) HID path uses report ID `3`; the
adapter uses its compact two-report keyboard record format, not the older
`FE` protocol.
The HID report descriptor confirms the wire format is 65 bytes total: the
report ID plus a 64-byte payload.

## Verified MacroPilot layout

The successful test established that firmware key ID 1 is the physical
bottom-left key. `--apply-macropilot-layout` programs the following neutral
layout on layer 1:

| Physical control | Neutral key |
| --- | --- |
| Top row, left → right | F13, F14, F15 |
| Bottom row, left → right | F16, F17, F18 |
| Knob counterclockwise / press / clockwise | F19 / F21 / F20 |

Use the matching preview command to inspect all generated packets before an
apply operation. Writing is always explicit:

```sh
tools/macropilot-sikai-map --apply-macropilot-layout
```

Some pads boot into factory layer 0 after a USB reconnect. For those pads use
the explicit boot-layer variant, which writes the same neutral layout to layer
0:

```sh
tools/macropilot-sikai-map --apply-macropilot-boot-layout
```

## Limits

This adapter configures the key and knob outputs only. LED and RGB control are
deliberately out of scope until their commands are independently verified.
The companion app should react to the neutral F-keys on the host, which keeps
the physical device useful with any workflow and avoids tying feedback to one
vendor firmware.
