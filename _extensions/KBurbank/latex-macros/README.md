# LaTeX Macros Handler

A Quarto extension for handling LaTeX macros in non-LaTeX output formats.

## Features

- **Inject LaTeX macros** from external `.tex` files into documents
- **Parse and convert** LaTeX syntax to native Pandoc elements
- **Highlight unparseable LaTeX** in styled containers for easy debugging
- **Re-parse markdown** inside LaTeX-generated divs to preserve formatting

## Installation

### Standalone

```bash
quarto add path/to/latex-macros
```

### As part of beamer-reveal

The `latex-macros` extension is **automatically included** (via extension embedding) when you install `beamer-reveal`. No separate installation needed!

## Usage

Add custom macro files in your document YAML:

```yaml
---
title: My Document
latex_macros_files:
  - my-macros.tex
  - more-macros.tex
---
```

Or specify a single file:

```yaml
---
latex_macros_file: my-macros.tex
---
```

If no files are specified, the extension looks for `latex_macros.tex` by default.

## How It Works

1. **inject_latex_macros.lua**: Reads `.tex` files and expands macros using Pandoc's LaTeX parser
2. **parse_latex_simple.lua**: Converts raw LaTeX blocks/inlines to native elements, wraps unparseable content

## Styling Unparsed LaTeX

Add CSS to style unparseable LaTeX (shown with class `unparsed-latex`):

```css
.unparsed-latex {
  color: red;
  font-family: monospace;
  background-color: #ffeeee;
}
```

