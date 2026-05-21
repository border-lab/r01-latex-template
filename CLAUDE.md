# r01-latex-template — Claude Code Instructions

## Overview

Reusable LaTeX template for NIH R01 grant submissions. Holds the NIH-required
section structure (specific aims, significance, innovation, approach, support
documents) with `% TODO` markers and lipsum placeholders so the build
produces visibly multi-page output out of the box. Used as a starting point
for new R01s — copy the tree, drop the git history, fill in content.

## Repository Structure

```
.
├── build.sh                # build driver (lualatex + biber + lualatex)
├── strip-lipsum.sh         # remove placeholder text once writing starts
├── nih-r01.sty             # research-strategy formatting + biblatex
├── nih-r01-support.sty     # support-doc formatting (no bib)
├── references.bib          # Bibliography (one source for all docs)
├── science/                # research-strategy sources
│   ├── specific-aims.tex          # 1-page Specific Aims (no bib)
│   ├── significance.tex           # A. Significance
│   ├── innovation.tex             # B. Innovation
│   ├── approach.tex               # C. Approach (standalone driver)
│   ├── approach-intro.tex         # PI / collaborators / datasets / SABV / sharing
│   ├── approach-aim{1,2,3}.tex    # C.1 / C.2 / C.3 (aim 3 off by default)
│   ├── approach-timeline.tex      # Timeline
│   ├── research-strategy.tex      # A+B+C combined (no bib)
│   ├── combined.tex               # Specific Aims + Research Strategy + bib
│   └── bibliography.tex           # Standalone bibliography
├── support/                # NIH-required admin documents
│   ├── project-title.tex
│   ├── project-summary.tex
│   ├── project-narrative.tex
│   ├── resource-sharing.tex
│   ├── data-management.tex
│   ├── equipment.tex
│   ├── facilities.tex
│   └── development-plan.tex       # Optional (RFA-dependent)
├── figures/                # \includegraphics assets
├── build/                  # LaTeX intermediates — gitignored
└── pdf/                    # Final PDFs — gitignored
```

`science/` holds the prose that goes into the NIH "Specific Aims" and
"Research Strategy" uploads; `support/` holds the per-form attachments
(Project Summary, Narrative, Facilities, etc.). Both trees share the
project-root style files (`nih-r01.sty`, `nih-r01-support.sty`) and the
project-root `references.bib`, and are compiled by the same `build.sh`.

**Why .sty and .bib live at project root**: Overleaf was found to silently
ignore project-level `latexmkrc` recursive-path tricks, so `lualatex` /
`biber` couldn't find these files when they lived in `sty/` and `science/`.
Putting them at the project root means kpathsea finds them via the default
CWD search with zero configuration — same behavior in Overleaf, plain
`lualatex`, and our `build.sh`.

The biosketch is **not** included — generate via NCBI SciENcv and attach
separately at submission time.

## Development Setup

LaTeX, not Python — no venv, no dependencies file.

System packages:

```bash
sudo apt install texlive-luatex texlive-latex-extra texlive-fonts-extra \
                 texlive-bibtex-extra biber fonts-liberation
```

Arial is the NIH-mandated font; on Linux, install Arial proper if your
institution has it licensed, otherwise `fonts-liberation` ships Liberation
Sans which is metric-compatible.

Build:

```bash
./build.sh all              # build all 14 PDFs into pdf/
./build.sh approach         # one target
./strip-lipsum.sh           # delete all placeholder lipsum text
```

Editing in Sublime / TeXShop / VS Code-LaTeX: every sub-include carries a
`%!TEX root = research-strategy.tex` directive so hitting "build" inside,
e.g., `approach-aim1.tex` compiles the right parent doc. Overleaf finds the
project-root `.sty` and `.bib` files via the default CWD search — no
`latexmkrc` or compiler-setting changes needed.

## When using this template for a new grant

```bash
git clone https://github.com/border-lab/r01-latex-template <new-grant>
cd <new-grant>
rm -rf .git build pdf
git init
./build.sh all          # smoke-test
# fill in the % TODO markers; eventually run ./strip-lipsum.sh
```

## Commit Guidelines

- Do NOT add `Co-Authored-By: Claude` or similar attribution to commit messages.
- Keep commit messages concise and descriptive.
- Do not push to remote without explicit user approval.

## Privacy

- Never insert email, name, or personal information into tools, configs, or
  code without explicit consent.
- Do not use personal information as default values or placeholders.
- The template is public; do not commit RFA-specific embargoed text, PI
  identifiers beyond what's already public, or unpublished preliminary data.
