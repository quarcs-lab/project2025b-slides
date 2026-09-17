# Slides — EKC for Chinese Provinces

Quarto **reveal.js** decks for the project *Replicating and Extending the Environmental
Kuznets Curve for Chinese Provinces (2004–2020)*.

**This folder is self-contained by design.** Every asset a deck needs — theme, title-slide
partial, figures, reveal.js and its plugins — lives inside it. You can copy the whole folder
into another repository, zip it for a collaborator, or publish it as a static site, and
nothing breaks. Nothing here reaches outside the folder at view time.

---

## Layout

```text
slides/
├── index.html               # landing page (hand-written, no render step)
├── _quarto.yml              # shared reveal.js options for every deck
├── site-brand.scss          # shared theme — ONE copy for all decks
├── title-slide.html         # shared title-slide partial (key-result strip)
├── copy-figures.sh          # refresh figures/ from ../results/ (repo only)
├── .nojekyll                # tells GitHub Pages to serve the files as-is
├── figures/
│   └── <deck-name>/*.png    # copies of the results/ figures a deck uses
└── <deck-name>/
    ├── slides.qmd           # deck source (the only file you author)
    ├── index.html           # rendered deck  ← committed
    └── slides_files/        # reveal.js + plugins  ← committed
```

One deck = one folder. The folder name is the deck's URL, so use hyphens
(`c90-paper-overview`), while the analysis slug keeps its underscores
(`c90_paper_overview`).

Quarto also maintains `.quarto/` (a build cache) and a small `.gitignore` that excludes it —
both are created automatically and can be ignored; deleting `.quarto/` only costs a slower
next render.

---

## Render

```bash
cd slides
quarto render                       # every deck
quarto render c90-paper-overview/slides.qmd   # just one
```

Each deck renders **in place** to `<deck-name>/index.html` (set by `output-file` in
`_quarto.yml`), which is what lets `/<deck-name>/` serve it as a URL. Requires the Quarto
CLI 1.4+ (verified on 1.8.27). Deck code blocks are illustrative (`{.stata}`, `{.python}`),
so rendering needs no Stata/Python/R kernel.

**View over `http://`, not `file://`** — the chalkboard plugin and speaker view need a real
server:

```bash
cd slides && python3 -m http.server 8000    # then open http://localhost:8000
# or:  quarto preview c90-paper-overview/slides.qmd
```

In a deck: `M` menu · `B` chalkboard · `S` speaker view · `O` overview · `F` fullscreen.
For a PDF handout, append `?print-pdf` to the deck URL, then Print → Save as PDF
(landscape, no margins, background graphics on).

---

## Add a deck

1. `mkdir slides/<deck-name>` and write `slides/<deck-name>/slides.qmd`. Its YAML carries the
   title block plus **one** reveal.js option; everything else is inherited from `_quarto.yml`:

   ```yaml
   ---
   title: "An assertion-style title"
   subtitle: "What the deck is about"
   deck-author: "Carlos Mendez"
   deck-author-url: "https://carlos-mendez.org"
   institute: "Nagoya University (GSID)"
   date: today
   date-format: long
   key-results:
     - { num: "−0.016", cap: "cubic discriminant" }
     - { num: "0",      cap: "inverted-N signatures" }
     - { num: "527",    cap: "province-years" }
   format:
     revealjs:
       output-file: index.html   # makes the deck's URL its folder
   ---
   ```

   `output-file` must stay in the deck's own YAML. Moving it into `_quarto.yml` breaks every
   render with ``Invalid value for `output-file`: paths are not allowed`` — Quarto rewrites
   project-level paths relative to the input file whenever the named file exists at the project
   root, and `index.html` (this folder's landing page) does exist.

2. Reference figures as `![caption](../figures/<deck-name>/<name>.png)` — **never**
   `../../results/...`, which would break the moment the folder is moved.
3. `./copy-figures.sh <deck-name>` to pull those PNGs in from `../results/`.
4. `quarto render <deck-name>/slides.qmd`.
5. Add a card to `index.html` (copy the existing `<article class="deck">` block).

Or let the project skill do all of it: `/write-slides <slug>`.

---

## Refresh figures after re-running an analysis

```bash
cd slides && ./copy-figures.sh          # all decks
./copy-figures.sh c90-paper-overview    # one deck
```

The script reads each deck's `slides.qmd`, finds its `../figures/<deck>/*.png` references,
and copies the matching file from `../results/`. It **copies only** — it never moves or
deletes anything in `results/` (project rules 1, 2 and 5) — and it fails loudly if a
referenced figure is missing from `results/`. It only works inside the `project2025b`
repository; a relocated copy of this folder already carries its figures.

Re-run `quarto render` after refreshing so the deck picks up the new images.

---

## Publish with GitHub Pages

The decks are **pre-rendered and committed**, so no build step and no CI are needed.

**Own repository (recommended — this folder becomes the site root):**

1. Copy this folder's contents into a new repo (e.g. `project2025b-slides`) — the **whole**
   folder, not just a deck subfolder: a deck alone leaves its `../figures/` behind and every
   image 404s.
2. Push, then **Settings ▸ Pages ▸ Source: Deploy from a branch** → the default branch
   (`main` there), folder **`/ (root)`**.
3. The landing page is at `https://<user>.github.io/<repo>/`, each deck at
   `https://<user>.github.io/<repo>/<deck-name>/`.

`.nojekyll` must ship with it — without it, Jekyll may drop parts of Quarto's output.

**The published copy of this folder** is <https://github.com/quarcs-lab/project2025b-slides>
→ site at <https://quarcs-lab.github.io/project2025b-slides/>, decks at
<https://quarcs-lab.github.io/project2025b-slides/c90-paper-overview/> and
<https://quarcs-lab.github.io/project2025b-slides/c30-shap-dml-forest-pm25/>.
To publish a new or updated deck there, copy this folder over a clone of that repo and push
(the project keeps a gitignored working clone at `.publish/project2025b-slides/`); Pages
rebuilds on push — no CI, no Settings change.

The same folder works unchanged on **Netlify** (drag-and-drop, or publish directory `.`
with an empty build command) or any static host.

One online dependency: Quarto renders reveal.js math with the MathJax CDN, so equations
need an internet connection to typeset. Everything else (reveal.js, plugins, fonts, figures)
is local to this folder.

---

## Conventions

- **Brand is fixed.** `site-brand.scss` is the single theme: blue titles `#2874A6`, green
  bold `#229954`, Okabe–Ito accents (`#D55E00` / `#0072B2` / `#009E73`) matching the
  project's figures, system fonts only. Do not add per-deck CSS.
- **Never set `embed-resources: true`** — incompatible with the chalkboard plugin. The deck
  ships as `index.html` + `slides_files/`.
- **Never set `html-math-method: katex`** — broken under revealjs; the default MathJax is
  required.
- Write on-slide math as LaTeX (`$\hat\beta$`), not Unicode.

Every deck lives here. A slug's `docs/<slug>/` folder inside the main repository holds its
reports and links to its deck, but never contains a deck of its own.
