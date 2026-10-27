# docs/design/screens/

Put every exported Stitch screen image here, one PNG per screen/state, named with the screen ID:

    P1-01-splash.png
    P2-02-groups-populated.png
    P5-01-add-expense-equal.png
    P7-04-itemized-service-and-tax.png

IDs follow `docs/design/STITCH_PROTOTYPE_LINKING.md` (section 1). Prompts can then say "implement screen P7-04" and the agent opens that exact file.

Tips
- Export at the design size (360x800) or 2x; keep each file small (compress PNGs).
- Optional: `docs/design/stitch-export/` for any HTML/code export from Stitch (reference only; the app is written in Flutter).
- Put tokens (colors, type, spacing, radii) in `docs/design/DESIGN.md`.
