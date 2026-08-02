# Upstream acknowledgments

MacroPilot's generic CH57x profile is designed around the configuration format
and documented protocol implemented by
[kriomant/ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool)
(MIT OR Apache-2.0). The reference source reviewed for this kit was commit
`bdbffca`.

MacroPilot does not bundle the upstream executable or vendor software. Users
should obtain and review the upstream tool independently before any hardware
configuration upload.

The compact configuration protocol used by the reference `1189:8890` pad was
cross-checked against [this public reverse-engineering discussion](https://stackoverflow.com/questions/75870303/hid-macropad-key-programming-doesnt-give-expected-results).
MacroPilot's mapper is a clean C implementation of the observed device protocol.
