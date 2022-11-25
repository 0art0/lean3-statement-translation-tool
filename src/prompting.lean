import declaration_with_docstring
import querying

/-- A list of declarations from `mathlib` with docstrings similar to the given sentence. -/
meta def similar_prompts (s : string) (n : nat) : io (list declaration_with_docstring) := do
  io.print_ln "Fetching similar prompts from `mathlib` ...",
  sim_stmts ← get_similarity_prompts s n,
  sim_stmts.mmap $ λ j, io.of_except (declaration_with_docstring.from_json j)

/-- The declarations available in the context. -/
meta def context_prompts : io (list declaration_with_docstring) := 
  io.run_tactic declaration_with_docstring.module_decls

/-- Build a prompt consisting of docstrings and theorem statements for querying Codex. -/
def build_prompt (decls : list declaration_with_docstring) : string :=
  decls.foldr (λ d prompt, d.to_full_string ++ "\n\n" ++ prompt) string.empty

/-- Produce Lean translations of a statement by querying Codex with a custom prompt -/
meta def get_translations (stmt : string) 
    (n_sim := 15) (prompt_suffix := "theorem") : io (list string) := do
  sim_prompts ← similar_prompts stmt n_sim,
  ctx_prompts ← context_prompts,
  let all_prompts := sim_prompts ++ ctx_prompts,
  let main_prompt := (build_prompt all_prompts) ++ sformat!"/-- {stmt} -/\n" ++ prompt_suffix,
  -- io.print main_prompt,
  io.print_ln "Querying Codex ...",
  translations ← completion_request.get_codex_completions main_prompt,
  return $ translations.map (λ t, prompt_suffix ++ t)

/-- Post-process the Codex completions by typechecking and adding the completion prefix. -/
meta def process_translations (stmt : string)
    (n_sim := 15) (completion_prefix := "theorem") : tactic (list declaration_with_docstring × list declaration_with_docstring) := do
  tactic.trace sformat!"Translating {stmt} to Lean code ...\n",
  translations ← tactic.unsafe_run_io $ get_translations stmt n_sim completion_prefix,
  let translation_decls := translations.erase_dups.map $ λ t, declaration_with_docstring.from_string t stmt,
  (typecorrect_translations, failed_translations) ← translation_decls.split_with $ 
      (functor.map option.is_some) ∘ declaration_with_docstring.validate,
  return (typecorrect_translations, failed_translations)