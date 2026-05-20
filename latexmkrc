# latexmkrc — for Overleaf compatibility.
#
# Adds every subdirectory of the project to TEXINPUTS and BIBINPUTS so that
# .sty files in sty/ and .bib files in science/ are found regardless of which
# .tex file is set as the Overleaf main document. The trailing // makes the
# search recursive.
#
# Not used by the local build.sh (which sets TEXINPUTS/BIBINPUTS itself), but
# harmless when present.

ensure_path('TEXINPUTS', './/');
ensure_path('BIBINPUTS', './/');
