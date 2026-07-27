# App Store screenshot sequence

Use **real interface screens** only. Do not place pages inside decorative phone mockups, floating glass cards, or collage frames. Caption text must stay legible at phone-sized App Store preview scale.

## Production rules

1. Capture from a real device or Flutter iOS/Android simulator at App Store sizes (prefer **iPhone 6.7"** 1290×2796).
2. Full-bleed UI fills the frame. Status bar may show; no third-party device chrome.
3. Overlay caption sits in a solid or softly graduated band **above or below** the UI—never over critical text. Use large type; keep caption to one or two short lines.
4. Use fictional memorial names and gentle sample content (no real bereaved persons’ private details).
5. Hide debug banners, snackbars, empty states that look unfinished, and trial countdowns on Home.
6. Prefer light cream/parchment theme so body text stays readable in the store grid.

## Sequence

| # | Caption | Show (real screen) | Route / path |
|---|---------|----------------------|--------------|
| 1 | A private place for everything you still wish you could say. | Simple **Letter** entry (title + a few short paragraphs; Save and Step Away visible if space) | `/entry/…/edit` or detail of a letter |
| 2 | Save the little things before they fade. | **Small memory cards**: habits, sayings, favorite foods, ordinary details | Library filtered to Memories, or Home Recent with several short memories |
| 3 | Capture a sentence, photo, voice, dream, or sign. | **Quick capture** with mode chips / attach options visible | `/capture` |
| 4 | No streaks. No pressure. Nothing to finish. | Calm **Home** — greeting, four save actions, quiet Recent (no badges, no countdowns) | `/shell/home` |
| 5 | Preserve the voices and stories your family should never lose. | **Voice Keepsakes** hub or editor **and** an **interview**-style memory (Someone else’s story) | `/voice-keepsakes` + memory with interview template |
| 6 | Turn scattered memories into a beautiful keepsake. | Polished **PDF / Keepsake preview** (Cardinal Garden or Soft Neutral) | `/keepsake-preview` or export preview |
| 7 | Private by default. Yours even if you cancel. | **Biometric lock**, encrypted **backup**, **export**, and **delete** controls | Settings + Data rights (may be one composed scroll or two adjacent system screens—still real UI, not a marketing collage) |

## Caption text (copy-paste)

```
1. A private place for everything you still wish you could say.
2. Save the little things before they fade.
3. Capture a sentence, photo, voice, dream, or sign.
4. No streaks. No pressure. Nothing to finish.
5. Preserve the voices and stories your family should never lose.
6. Turn scattered memories into a beautiful keepsake.
7. Private by default. Yours even if you cancel.
```

## Sample content for legibility

**Screenshot 1 — Letter**

- Title: short (e.g. “I still talk to you in the car”)
- Body: 3–5 short lines, generous spacing, no wall of text

**Screenshot 2 — Memory cards**

Show four compact items with titles only or one-line bodies:

- Habit — “Always left the porch light on”
- Saying — “We’ll figure it out in the morning”
- Favorite food — “Sunday gravy, extra garlic”
- Ordinary detail — “Hummed while folding laundry”

**Screenshot 3 — Quick capture**

Open capture with Type selected and a single unfinished sentence in the field; photo / voice affordances visible.

**Screenshot 4 — Home**

Memorial line like “Thinking of …” ; Letter / Memory / Meaningful Moment / Keepsake actions; Recent with 1–2 calm items. No prompt sheet open.

**Screenshot 5 — Voice + interview**

- Voice Keepsakes list or editor with context fields (who is speaking, transcript snippet)
- Nearby or prior frame: Memory using template **Someone else’s story** (interview), one question + short answer visible

**Screenshot 6 — Keepsake PDF**

Preview page with cover or interior spread; theme name readable; avoid tiny unreadable body paragraphs—show headings and a short sample letter excerpt.

**Screenshot 7 — Privacy controls**

Settings **Private by default** block: Biometric lock, Encrypted cloud backup, Export your data, Delete account & data. Capture with those rows in frame; caption stays outside the UI.

## Export checklist

- [ ] All seven frames, same device size
- [ ] Captions match the sequence exactly
- [ ] No floating mockups / device bezels from design tools
- [ ] Text readable when the thumbnail is ~⅙ screen width
- [ ] Uploaded to App Store Connect in order 1→7

## Related

Listing copy: [APP_STORE_LISTING.md](APP_STORE_LISTING.md)
