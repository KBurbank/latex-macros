--- inject_unsupported_commands.lua
--- Reads a tex file specified in YAML metadata and injects its contents
--- for use by parse_latex.lua

function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

function Pandoc(doc)
  -- Get tex file path(s) from metadata
  local tex_files = {}
  
  if doc.meta.latex_macros_files then
    -- Multiple files specified
    for _, file in ipairs(doc.meta.latex_macros_files) do
      table.insert(tex_files, pandoc.utils.stringify(file))
    end
  elseif doc.meta.latex_macros_file then
    -- Single file specified
    table.insert(tex_files, pandoc.utils.stringify(doc.meta.latex_macros_file))
  else
    -- Default
    table.insert(tex_files, "latex_macros.tex")
  end
  
  -- Read and concatenate all tex files
  local tex_content = ""
  for _, tex_file in ipairs(tex_files) do
    local content = read_file(tex_file)
    if content then
      tex_content = tex_content .. content .. "\n"
      io.stderr:write("  → Loaded macros from " .. tex_file .. "\n")
    else
      io.stderr:write("Note: " .. tex_file .. " not found. Skipping.\n")
    end
  end
  
  if tex_content == "" then
    io.stderr:write("Note: No macro files found. Skipping macro injection.\n")
    return doc
  end
  
  -- Insert macros at the beginning wrapped in a hidden div
  local macro_block = pandoc.RawBlock("tex", tex_content)
  local hidden_div = pandoc.Div({macro_block}, pandoc.Attr("", {"hidden"}, {style = "display: none;"}))
  table.insert(doc.blocks, 1, hidden_div)
  
  -- walk the document, and replace all raw tex inlines with just strings

  -- Convert document to markdown string
  local latex_str = pandoc.write(pandoc.Pandoc(doc.blocks, doc.meta), 'markdown+raw_tex-raw_attribute')
  
  -- Re-read with latex_macros enabled to expand all macros
  local new_doc = pandoc.read(latex_str, 'markdown+raw_tex')
  
  -- Preserve original metadata
  new_doc.meta = doc.meta
  
  io.stderr:write("✓ Injected and expanded LaTeX macros\n")
  
  return new_doc
end
