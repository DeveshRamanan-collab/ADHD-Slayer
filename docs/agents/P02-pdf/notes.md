# P02-pdf notes
- Inputs logged with line counts: docs/evidence/p00/p02-inputs-pdf-P02-pdf-20261001T142103.log (cmd: wc -l on the PDF and the four notes files).
- The Read tool could not render the PDF (pdftoppm missing). Text was extracted with pypdf into the scratchpad: docs/evidence/p00/p02-pdf-extract-P02-pdf-20261001T142113.log. The extraction reported 80 pages; every page was read in chunks of at most 420 lines.
- The four raster figures (p19 day-one chart, p37 lifestyle switching, p71 architecture, p74 roadmap) were decoded from the PDF image streams to PNG in the scratchpad and viewed as images.
- Notes-file tables record each heading's own assertions, acceptance criteria and inferences; the underlying PDF facts are rows in the PDF table.
- Session was cut by a usage limit after line 376; resumed and finished from the pdf_01_20 table onward without rewriting finished rows.
- Self-run of the validator regexes on the part (the validator itself skips docs/parts/) found 8 verification verbs; all rephrased; 0 remaining.
