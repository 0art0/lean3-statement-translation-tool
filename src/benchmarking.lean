import prompting

/-- Summarises the result of a statement translation as a `json` object, optionally including information about the parameters used.
    This is useful for benchmarking as well as performing translations in batches and logging. -/
meta def translation_summary (stmt : string) (record_params := ff)
    (use_fixed := tt)
    (n_sim := 15) 
    (use_ctx := tt) 
    (temp := 6) 
    (n := 7) 
    (completion_prefix := "theorem") : io json := do
  (prompt, translations) ← get_translations stmt use_fixed n_sim use_ctx temp n completion_prefix,
  let translation_decls := translations.map $ λ t, declaration_with_docstring.from_string t stmt,
  (typecorrect_translations, failed_translations) ← translation_decls.split_with $ 
      (functor.map option.is_some) ∘ io.run_tactic ∘ declaration_with_docstring.validate,
  return $ json.object $ 
    (if record_params then
      [("parameters", json.object $ [
          ("use_fixed?", use_fixed), 
          ("n_similar", n_sim), 
          ("use_context?", use_ctx), 
          ("temperature", temp), 
          ("n_completions", n)])]
      else []) ++ [
        ("statement", stmt),
        ("success?", json.of_bool $ typecorrect_translations.length > 0),
        ("prompt", prompt),
        ("typecorrect_translations", typecorrect_translations.map declaration_with_docstring.to_json),
        ("failed_translations", failed_translations.map declaration_with_docstring.to_json)
      ]

/-- Reads in `input_file` (**without** `.json` suffix) as a list of strings,
    translates each string and summarises the results, and finally writes the results back to a `.json` file. -/
meta def main (input_file : string)
    (use_fixed := tt)
    (n_sim := 15) 
    (temp := 6) 
    (n := 10) 
    (completion_prefix := "theorem") : io unit := do
  -- the input file as a `json` object
  input ← io.fs.read_file (input_file ++ ".json") >>= pure ∘ json.parse ∘ buffer.to_string,
  stmts ← io.of_except (do
    data ← except.of_option input "failed to parse input file as json",
    data_arr ← data.as_array,
    data_arr.mmap json.as_string),
  output ← stmts.mmap $ λ s, translation_summary s ff use_fixed n_sim ff temp n completion_prefix,
  output_file ← io.mk_file_handle (sformat! "{input_file}-results-F{use_fixed}-S{n_sim}-T{temp}-N{n}.json") io.mode.write,
  io.fs.write output_file $ (json.unparse output).to_char_buffer