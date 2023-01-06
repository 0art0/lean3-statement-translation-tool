import declaration_with_docstring

meta def parse_stmt (stmt : string) := (declaration_with_docstring.from_string stmt).validate

meta def parse_stmts (stmts : list string) : tactic (list string × list string) :=
  stmts.split_with $ λ stmt, option.is_some <$> parse_stmt stmt 

meta def main (input_file : string := "data/test_statements.json") : io unit := do
  io.print_ln sformat! "Processing {input_file} ...",
  -- the input file as a `json` object
  input ← io.fs.read_file input_file >>= pure ∘ json.parse ∘ buffer.to_string,
  some data ← pure input | io.fail "failed to parse input file as json",
  data_arr ← io.of_except $ data.as_array,
  output : list json ← data_arr.mmap (λ entry, do
    translations ← io.of_except $ entry.lookup_as "outputs" (λ j, j.as_array >>= list.mmap json.as_string),
    (typecorrect_stmts, failed_stmts) ← io.run_tactic $ parse_stmts translations,
    entry' : json ← io.of_except $ entry.insert 
      [("typecorrect_ouputs", json.of_string <$> typecorrect_stmts), 
       ("failed_outputs", json.of_string <$> failed_stmts)],
    return entry'
    ), 
  io.print_ln "Translating statements...",
  let output_file := input_file,
  io.print_ln sformat!"Writing output to {output_file}...",
  output_file ← io.mk_file_handle output_file io.mode.write,
  io.fs.write output_file $ (json.unparse output).to_char_buffer