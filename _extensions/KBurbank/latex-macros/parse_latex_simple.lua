--- parse-latex.lua – parse and replace raw LaTeX snippets
---
--- Copyright: © 2021–2024 Albert Krewinkel
--- License: MIT – see LICENSE for details

PANDOC_VERSION:must_be_at_least '2.9'

if FORMAT:match 'latex' then
  return {}
end

-- Helper function to check if format is TeX-like
local function is_tex_format(format)
  return format:match 'tex' or format:match 'latex'
end

-- Helper function to check if LaTeX is a Beamer command that should be left alone
local function is_beamer_command(text)
  local beamer_commands = {"^\\pause", "^\\only<", "^\\onslide<", "^\\hid<"}
  for _, pattern in ipairs(beamer_commands) do
    if text:match(pattern) then
      return true
    end
  end
  return false
end

-- Helper function to create styled container for unparseable LaTeX
-- Can accept either a string or a raw element
local function wrap_unparsed(text_or_elem, is_inline)
  -- If it's a raw element (has .text and .format fields), check format first
  if type(text_or_elem) == 'table' and text_or_elem.text then
    if not is_tex_format(text_or_elem.format) then
      return text_or_elem
    end
    -- Check if it's a Beamer command - if so, leave it as raw LaTeX
    if is_beamer_command(text_or_elem.text) then
      return text_or_elem
    end
    text_or_elem = text_or_elem.text
  end
  
  -- Also check string form for Beamer commands
  if is_beamer_command(text_or_elem) then
    return nil  -- Don't wrap Beamer commands
  end
  
  local content = pandoc.Str(text_or_elem)
  local attr = pandoc.Attr("", {"unparsed-latex"}, {})
  return is_inline and pandoc.Span(content, attr) or pandoc.Div(pandoc.Para(content), attr)
end

-- Parse and replace raw TeX blocks
function RawBlock(raw)
  if not is_tex_format(raw.format) then return end
  
  local blocks = pandoc.read(raw.text, 'latex').blocks
  
  if #blocks == 0 then -- if the block contained only unrecognized latex, Pandoc won't return any blocks from the read. But we still want to wrap the unrecognized latex in a styled container.
    return wrap_unparsed(raw.text, false)
  end
  
  return pandoc.walk_block(pandoc.Div(blocks), {
    RawBlock = function(elem) return wrap_unparsed(elem, false) end,
    Div = function(div)
      -- Re-parse the content of the Div as markdown to catch markdown formatting
      local content_str = pandoc.write(pandoc.Pandoc(div.content), 'plain')
      local new_blocks = pandoc.read(content_str, 'markdown+raw_tex').blocks
      div.content = new_blocks
      return div
    end
  }).content
end

-- Parse and replace raw TeX inlines
function RawInline(raw)
  if not is_tex_format(raw.format) then return end
  local inlines = pandoc.utils.blocks_to_inlines(
    pandoc.read(raw.text, 'latex').blocks
  )
  if #inlines == 0 then
    return wrap_unparsed(raw.text, true)
  end
  
  return pandoc.walk_inline(pandoc.Span(inlines), {
    RawInline = function(elem) return wrap_unparsed(elem, true) end
  }).content
end

