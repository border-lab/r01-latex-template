#!/bin/bash
# strip-lipsum.sh — remove all \lipsum[...] placeholder calls and the
# \usepackage{lipsum} / \RequirePackage{lipsum} lines that load the package.
#
# Run once you've started replacing the lorem-ipsum placeholders in
# science/*.tex with real content. The script is idempotent — running it
# twice is harmless.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Stripping \\lipsum[...] calls from science/*.tex..."
sed -i '/\\lipsum\[/d' "$ROOT"/science/*.tex

echo "Removing lipsum package load from nih-r01.sty..."
sed -i '/\\RequirePackage{lipsum}/d' "$ROOT"/nih-r01.sty
sed -i '/^% -- Placeholder text/d' "$ROOT"/nih-r01.sty

echo "Removing lipsum package load from science/specific-aims.tex..."
sed -i '/\\usepackage{lipsum}/d' "$ROOT"/science/specific-aims.tex
sed -i '/^% -- Placeholder text/d' "$ROOT"/science/specific-aims.tex

echo
echo "Done. Rerun ./build.sh all to confirm the template still builds with"
echo "your filled-in (or empty TODO) content."
