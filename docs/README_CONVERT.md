# Convert the documentation into PPTX / DOCX

You can convert the markdown files in this `docs/` folder into PowerPoint (`.pptx`) and Word (`.docx`) using `pandoc`.

Install pandoc (macOS Homebrew):

```bash
brew install pandoc
```

Convert presentation markdown to PPTX (slide level: `##`):

```bash
cd /Users/premkumar/develop/flutter_projects/demo/docs
pandoc cloudly_presentation.md -o cloudly_presentation.pptx --slide-level=2
```

Convert documentation markdown to Word (.docx):

```bash
pandoc cloudly_documentation.md -o cloudly_documentation.docx
```

Convert tech stack to PDF (optional):

```bash
pandoc cloudly_tech_stack.md -o cloudly_tech_stack.pdf
```

Notes:
- The generated `.pptx` will map `##` headings to slides. Tuning may be required for layout and styling.
- If you want a native Word `.docx` with custom styles, open the generated file in Microsoft Word and apply templates.

