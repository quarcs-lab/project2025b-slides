#!/usr/bin/env bash
#
# copy-figures.sh — refresh slides/figures/ from the project's results/ folder.
#
# Why this exists: this `slides/` folder must be SELF-CONTAINED so it can be moved
# to another repository and served by GitHub Pages with no broken assets. Decks
# therefore reference figures as `../figures/<deck>/<name>.png`, never
# `../../results/<name>.png`. This script keeps those copies in sync.
#
# It needs no manifest: it greps every `<deck>/slides.qmd` for figure references of
# the form `../figures/<deck>/<name>.png` and copies `../results/<name>.png` into
# place. Add a figure to a deck, rerun this, done.
#
# COPY ONLY — this script never moves or deletes anything in results/ (CLAUDE.md
# rules 1, 2 and 5).
#
# Portable to the stock macOS bash 3.2 (no mapfile, no associative arrays).
#
# Usage:
#   ./copy-figures.sh            # refresh every deck
#   ./copy-figures.sh <deck>     # refresh one deck, e.g. c90-paper-overview

set -euo pipefail

cd "$(dirname "$0")"

RESULTS="../results"

if [ ! -d "$RESULTS" ]; then
  cat >&2 <<'EOF'
copy-figures.sh: ../results not found.

This script only works inside the project2025b repository, where the source PNGs
live in results/. A relocated or shared copy of this slides/ folder already
contains its figures under figures/ — nothing to refresh, and nothing is broken.
EOF
  exit 1
fi

# --- resolve the deck list -------------------------------------------------
decks=""
if [ $# -gt 0 ]; then
  for d in "$@"; do
    d="${d%/}"
    if [ ! -f "$d/slides.qmd" ]; then
      echo "copy-figures.sh: no such deck: $d/slides.qmd" >&2
      exit 1
    fi
    decks="$decks $d"
  done
else
  for qmd in */slides.qmd; do
    [ -e "$qmd" ] || { echo "copy-figures.sh: no decks found (no */slides.qmd)." >&2; exit 1; }
    decks="$decks $(dirname "$qmd")"
  done
fi

copied=0
unchanged=0
problems=0

for deck in $decks; do
  # Every `../figures/<deck>/<name>.<ext>` reference in this deck's source.
  refs="$(grep -oE '\.\./figures/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+\.(png|jpg|jpeg|svg|gif)' \
            "$deck/slides.qmd" | sort -u || true)"

  if [ -z "$refs" ]; then
    echo "  $deck: no ../figures/ references — skipped"
    continue
  fi

  mkdir -p "figures/$deck"

  for ref in $refs; do
    rel="${ref#../figures/}"        # <deck>/<name>.png
    ref_deck="${rel%%/*}"
    name="${rel##*/}"

    # A reference into another deck's figures folder is an authoring error, not
    # something to silently copy into the wrong place.
    if [ "$ref_deck" != "$deck" ]; then
      echo "  ! $deck/slides.qmd references figures/$ref_deck/$name (another deck's folder)" >&2
      problems=$((problems + 1))
      continue
    fi

    src="$RESULTS/$name"
    dst="figures/$deck/$name"

    if [ ! -f "$src" ]; then
      echo "  ! missing source: results/$name (referenced by $deck/slides.qmd)" >&2
      problems=$((problems + 1))
      continue
    fi

    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      unchanged=$((unchanged + 1))
      continue
    fi

    cp -p "$src" "$dst"
    echo "  + $dst"
    copied=$((copied + 1))
  done
done

echo "copy-figures.sh: $copied copied, $unchanged already current, $problems problem(s)."
[ "$problems" -eq 0 ] || exit 1
