# ComicSmith for macOS — User Guide

A chat‑first studio for making comic scripts. You work page‑by‑page, drop into panels to sculpt details, and keep your world bible tight in References. Images are rough guides generated on demand. No locking, no fuss.

---

## 1) Big Picture

- **Three panes you can dock/tab/tear off:** **Chat**, **Content**, **Script**.  
- **Four Content modes:** **Issue** (pages), **Page** (panels), **Panel** (balloons & details), **References** (All + Detail).  
- **Chat model:** **Gemini Flash 2.5 (text)** for conversation and tool calls.  
- **Image model:** **Gemini Flash 2.5 Image** for thumbnails/roughs with clear **Generating…** states.  
- **Always‑on Script:** live, editable, structure‑aware. Follows focus.

---

## 2) The Panes

### Chat
Conversational co‑writing powered by Gemini Flash 2.5 (text). The assistant proposes diffs or calls tools (add page, insert panel, add balloon, update reference, trigger image generation). Hidden sync keeps the model current; you see only helpful replies.

### Content
Your visual work surface. Switch modes from the toolbar:
- **Issue Mode** — manage **pages** (add / remove / reorder).
- **Page Mode** — manage **panels** on the current page (add / remove / reorder). *(No balloon/text editing on the canvas here.)*
- **Panel Mode** — edit **one panel** (description, balloons, SFX, references) with medium‑fidelity visuals.
- **References** — **All References** (grid/list) and **Reference Detail** (single entry).

### Script
Always visible somewhere, live and editable. Mirrors the structured model and automatically scrolls to the current Page/Panel (Follow Focus can be toggled). Edits here instantly update the model.

---

## 3) Content Modes

### Issue Mode — pages at a glance
**Purpose:** create, delete, and reorder pages for the issue.

**View:** a scrollable board of **low‑fidelity page thumbnails** (generated from their panels), page numbers/titles, and warning badges.  
**You can:**
- **Add Page** (＋ button, context menu, or ⌘N)
- **Insert Before/After** a selected page
- **Remove Page** (Undo supported)
- **Reorder** pages by drag
- **Regenerate Thumbnails** for selected pages

Double‑click a page to open **Page Mode** on it. Thumbnail regen shows a page overlay **Generating…** and a toolbar counter, all via Gemini Flash 2.5 Image.

---

### Page Mode — panels, structurally
**Purpose:** **add / remove / reorder** panels on the current page. *(No panel editing in the canvas.)*

**View:** page grid with **low‑fidelity panel thumbnails**, panel numbers, chips for Speech/Thought/Caption/SFX, balloon load meters, and ⚠ continuity badges.  
**You can:**
- **Add Panel** (before/after)
- **Remove Panel** (Undo supported)
- **Reorder Panels** by drag or arrow controls
- **Change Layout Preset** (e.g., 6‑grid → 3‑tier; preserves order)
- **Regenerate Page Thumbnails**

**Not here:** no balloon or description editing on the canvas. Click a panel to enter **Panel Mode**, or type in **Script** (always allowed). Thumbnail regeneration is low‑fi; affected panels show **Generating…** until ready.

---

### Panel Mode — sculpt a single panel
**Purpose:** precise editing of description, balloons, SFX, and references with **medium‑fidelity** visuals.

**View:** medium‑fi rough, editable description, balloons with accurate wrap & tails, per‑balloon **fit meter**, optional guides.  
**Right‑click menu:**
- **Text:** Add Speech • **Add Thought** • Add Caption • Add SFX
- **Dialogue Tools:** Punch‑Up (AI) • Tighten to 12/18/22
- **Layout:** Insert Before/After • Split (V/H) • Reorder Up/Down • Make Splash
- **References:** Tag Characters • Tag Location/Props
- **Visuals:** Generate Visual Rough • Toggle Rough Overlay

**Image behavior:** description/reference changes trigger a panel **Generating…** overlay (Gemini Flash 2.5 Image). Dialogue‑only changes do **not** regenerate images.

---

### References — your world bible
Two sub‑modes that mirror Content’s approach.

#### All References
Grid/list of **Characters**, **Locations**, **Props** with low‑fi portraits/thumbnails, tags, and usage counts.

**You can:** create, rename, search/filter, run **Consistency Sweep**, and generate portraits/thumbnails (each shows **Generating…**).  
**Jump:** click any entry to open **Reference Detail**.

#### Reference Detail
Edit a single entry.

**Fields:** name, aliases, traits, voice notes, canonical visuals (e.g., “visor cracked since p2”), relationships, timeline notes.  
**Links:** see panels/pages where this appears; click to jump.  
**Images:** medium‑fi portrait/thumbnail generation with **Generating…** overlays.

---

## 4) Script — live, structure‑aware

**Syntax:**
```
Page 5 (6 Panels)
Panel 1: Description…
Dialogue (Red Comet): …
Thought (Red Comet): …
Caption: …
SFX: KRAKOOM
```
**Behavior:**
- Edits = model changes.
- Adding/removing “Panel N:” lines updates the panel count automatically.
- Changing “Page X (N Panels)” can insert/renumber with a preview sheet.
- Balloon overages show a subtle right‑margin meter; continuity conflicts underline facts with tooltips.
- Clicking “Panel 3” focuses it in Content; Follow Focus toggles auto‑scroll.

---

## 5) Images & “Generating…”

- **Engine:** **Gemini Flash 2.5 Image** for all thumbnails/roughs.  
- **Fidelity by mode:**
  - **Issue/Page:** **low‑fi** thumbnails (downscaled/dithered).
  - **Panel/Reference Detail:** **medium‑fi** roughs.
- **UI states:** Placeholder → **Generating…** (spinner overlay + toolbar counter “Images: n in progress”) → Ready → Error (Retry).
- **Triggers:**
  - Page thumbnails: on page creation, “Regenerate Thumbnails,” or when panel descriptions change and you request refresh.
  - Panel rough: on first open in Panel Mode, on description/reference edits, or “Generate Visual Rough.”
  - Reference portraits/thumbnails: on entry edits or “Generate Portrait/Thumb.”
- **Caching:** keyed by content hash (description + references + style seed). “Force Regenerate” bypasses cache.
- **Dialogue edits** do **not** regenerate images.

---

## 6) Creation & Editing Paths (all first‑class)

- **Issue Mode:** add/remove/reorder **pages**. (＋, context menu, ⌘N)  
- **Page Mode:** add/remove/reorder **panels** on the current page.  
- **Panel Mode:** edit text & balloons; layout tweaks; references.  
- **Script:** type directly to create/modify pages/panels/balloons.  
- **Chat:** ask for pages/panels; the assistant proposes diffs or calls tools; you Apply.

Everything stays in sync; Script always reflects reality.

---

## 7) Chat Brain — behavior & guardrails

- **Model:** **Gemini Flash 2.5 (text)**.  
- **Tool use:** assistant calls tools for Issue/Page/Panel/Reference ops and image generation triggers. Your app executes them and updates the model.  
- **Hidden sync:** after any change (from Chat/Script/UI), a compact **state summary** is *prepended* to the chat context (not visible to you) so the model is always current.  
- **No images in chat:** only structured text (focused page/panel and relevant bible snippets).  
- **Mode‑aware:** in Page Mode, it limits actions to panel structure; in Panel Mode, it can edit description/balloons/SFX and references.

---

## 8) Menus & Shortcuts

**File**  
- New Project (⌘⇧N) • Open (⌘O) • Save (⌘S)

**Issue**  
- **Issue Mode** (⌘1) • New Issue (⌘⌥N)  
- **New Page (⌘N)** • Insert Page Before/After • Remove Page • Reorder (drag)

**Page**  
- **Page Mode** (⌘2)  
- Add Panel Before/After • Remove Panel • Reorder Panels (drag or ⌘↑/⌘↓)  
- Change Layout Preset • Regenerate Thumbnails

**Panel**  
- **Panel Mode** (⌘3)  
- Add Speech/Thought/Caption/SFX • Punch‑Up (⌘⌥P) • Tighten (⌘⌥T → 12/18/22)  
- Insert Before/After • Split (V/H) • Reorder Up/Down • Make Splash  
- Generate Visual Rough

**References**  
- **All References** (⌘4) • New Character/Location/Prop • Consistency Sweep  
- From All → open **Reference Detail**; Generate Portrait/Thumb

**View**  
- Layout presets (All Three / Content+Script / Chat+Script)  
- Toggle panes: Chat (⌘⌥C) • Script (⌘⌥S) • Content (⌘⌥O)  
- Follow Focus (⌘⌥L)

---

## 9) Exports

- **Script:** Markdown / PDF / Plain Text (pages, panels, speakers, captions, SFX).  
- **Contact Sheet:** optional low‑fi page thumbnails.  
- **Bible:** Characters/Locations/Props summary (Markdown/PDF).

---

## 10) Project Structure

```
SeriesName/
  issue.yaml             # page order, titles
  pages/
    page_001.yaml        # panels, descriptions, balloons, refs
    page_002.yaml
  bible/
    characters.yaml
    locations.yaml
    props.yaml
  continuity.json        # derived flags + accepted exceptions
  assets/
    thumbs/              # low‑fi page/panel thumbs
    panels/              # medium‑fi panel roughs
    refs/                # reference portraits/thumbnails
  exports/
```

---

## 11) Typical Flow

1. **Issue Mode:** add Page 5 and 6, reorder them.  
2. **Page Mode (Page 5):** add two panels, remove an extra reaction panel, drag to reorder. Thumbnails show **Generating…**.  
3. **Panel Mode (P5 ▸ Panel 3):** add a Thought balloon, tighten to 18 words, tag “Red Comet.” Panel shows **Generating…** briefly after description tweak.  
4. **References:** open **All References**, create “Alien Dreadnought,” set traits & visual cues in **Reference Detail**; generate a portrait.  
5. **Script:** tweak a caption line; Script and Content stay synced.  
6. **Export:** Markdown script + contact sheet.

---

## 12) Troubleshooting

- **Images stuck on Generating…**: verify Gemini Image API key/quota; reduce parallel jobs; Retry from the overlay.  
- **Continuity noise:** open the flag → edit text or adjust the reference (e.g., “visor repaired on p7”).  
- **Script reordering surprises:** renumbering shows a preview sheet; Undo is atomic.

---

*Version:* 0.1 (Spec reflects Issue/Page/Panel/References modes; no lock mode; chat = Gemini Flash 2.5 text; images = Gemini Flash 2.5 Image.)

