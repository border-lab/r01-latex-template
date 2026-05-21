#!/bin/bash
# Build NIH R01 submission documents from LaTeX sources.
# Usage: ./build.sh [combined|aims|significance|innovation|approach|research-strategy|support|all]
#
# Layout:
#   science/   research-strategy .tex sources (specific-aims, significance,
#              innovation, approach.*, research-strategy, combined, bibliography)
#   support/   admin .tex sources (project-title/summary/narrative,
#              resource-sharing, data-management, equipment, facilities,
#              development-plan)
#   nih-r01*.sty, references.bib
#              shared style files + bibliography at project root (so Overleaf
#              and any other vanilla TeX setup finds them via the default
#              kpathsea search of CWD — no TEXINPUTS / latexmkrc tricks needed)
#   figures/   image assets referenced by \includegraphics
#   build/     LaTeX intermediates (.aux/.bbl/.bcf/...); .gitignored
#   pdf/       final PDFs; .gitignored
#
# 2-aim vs. 3-aim: edit science/approach.tex (and science/research-strategy.tex)
# and (un)comment the \input{approach-aim3.tex} line. No build-script change needed.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SCIENCE_DIR="$ROOT/science"
SUPPORT_DIR="$ROOT/support"
BUILD_DIR="$ROOT/build"
PDF_DIR="$ROOT/pdf"

mkdir -p "$BUILD_DIR" "$PDF_DIR"

# nih-r01*.sty and references.bib live at $ROOT (see Layout above).
export TEXINPUTS="$ROOT:$SCIENCE_DIR:$SUPPORT_DIR:$BUILD_DIR:"
export BIBINPUTS="$ROOT:$BUILD_DIR:"

# Copy bib so biber finds it relative to the .bcf in build/.
cp -u "$ROOT/references.bib" "$BUILD_DIR/references.bib" 2>/dev/null || true

build_tex() {
    # Full pipeline: lualatex + biber + lualatex.
    local src_dir="$1"
    local tex_name="$2"

    echo "Building ${tex_name}..."
    cd "$src_dir"
    lualatex -interaction=nonstopmode -output-directory="$BUILD_DIR" "${tex_name}.tex" 2>&1 | grep -E "^(!|Output)" || true
    cd "$BUILD_DIR"
    biber "$tex_name" 2>&1 | grep -E "INFO|WARN|ERROR" | tail -5 || true
    cd "$src_dir"
    lualatex -interaction=nonstopmode -output-directory="$BUILD_DIR" "${tex_name}.tex" 2>&1 | grep -E "^(!|Output)" || true

    cp "$BUILD_DIR/${tex_name}.pdf" "$PDF_DIR/${tex_name}.pdf"
    echo "  -> $PDF_DIR/${tex_name}.pdf"
}

build_simple() {
    # Single lualatex pass for docs without citations.
    local src_dir="$1"
    local tex_name="$2"

    echo "Building ${tex_name}..."
    cd "$src_dir"
    lualatex -interaction=nonstopmode -output-directory="$BUILD_DIR" "${tex_name}.tex" 2>&1 | grep -E "^(!|Output)" || true
    cp "$BUILD_DIR/${tex_name}.pdf" "$PDF_DIR/${tex_name}.pdf"
    echo "  -> $PDF_DIR/${tex_name}.pdf"
}

build_support() {
    echo "=== Building support documents ==="
    for doc in project-title project-summary project-narrative \
               resource-sharing data-management facilities equipment \
               development-plan; do
        build_simple "$SUPPORT_DIR" "$doc" || echo "  WARNING: ${doc} build failed"
    done
    echo "=== Support documents done ==="
}

build_approach() {
    # Build full approach (generates .bbl that bibliography reuses).
    build_tex "$SCIENCE_DIR" "approach"

    # Rebuild approach without bibliography (NIH wants bibliography uploaded separately).
    echo "Building approach (no bibliography)..."
    cd "$SCIENCE_DIR"
    lualatex -interaction=nonstopmode -output-directory="$BUILD_DIR" -jobname=approach \
        "\def\nobib{1}\input{approach.tex}" 2>&1 | grep -E "^(!|Output)" || true
    cp "$BUILD_DIR/approach.pdf" "$PDF_DIR/approach.pdf"
    echo "  -> $PDF_DIR/approach.pdf (without bibliography)"

    # Standalone bibliography document reuses .bbl from the approach build.
    # Skipped silently when references.bib has no entries cited (empty bib =
    # no pages output = no PDF). Once you add citations it will build.
    echo "Building bibliography..."
    cp "$BUILD_DIR/approach.bbl" "$BUILD_DIR/bibliography.bbl"
    cd "$SCIENCE_DIR"
    lualatex -interaction=nonstopmode -output-directory="$BUILD_DIR" "bibliography.tex" 2>&1 | grep -E "^(!|Output)" || true
    lualatex -interaction=nonstopmode -output-directory="$BUILD_DIR" "bibliography.tex" 2>&1 | grep -E "^(!|Output)" || true
    if [ -f "$BUILD_DIR/bibliography.pdf" ]; then
        cp "$BUILD_DIR/bibliography.pdf" "$PDF_DIR/bibliography.pdf"
        echo "  -> $PDF_DIR/bibliography.pdf"
    else
        echo "  (skipped — bibliography is empty; cite something in references.bib)"
    fi
}

case "${1:-all}" in
    combined)
        build_tex "$SCIENCE_DIR" "combined"
        ;;
    aims|specific-aims)
        build_simple "$SCIENCE_DIR" "specific-aims"
        ;;
    significance)
        build_tex "$SCIENCE_DIR" "significance"
        ;;
    innovation)
        build_tex "$SCIENCE_DIR" "innovation"
        ;;
    approach)
        build_approach
        ;;
    research-strategy|strategy)
        build_tex "$SCIENCE_DIR" "research-strategy"
        ;;
    support)
        build_support
        ;;
    all)
        echo "=== Building all R01 documents ==="
        echo ""
        build_simple "$SCIENCE_DIR" "specific-aims" || echo "  WARNING: specific-aims build failed"
        build_tex "$SCIENCE_DIR" "significance"     || echo "  WARNING: significance build failed"
        build_tex "$SCIENCE_DIR" "innovation"       || echo "  WARNING: innovation build failed"
        build_approach                              || echo "  WARNING: approach build failed"
        build_tex "$SCIENCE_DIR" "research-strategy" || echo "  WARNING: research-strategy build failed"
        build_tex "$SCIENCE_DIR" "combined"         || echo "  WARNING: combined build failed"
        build_support                               || echo "  WARNING: support docs build failed"
        echo ""
        echo "=== Done ==="
        ;;
    *)
        echo "Usage: $0 [combined|aims|significance|innovation|approach|research-strategy|support|all]"
        exit 1
        ;;
esac
