import declaration_with_docstring
import fixed_prompts
import querying

/-- A list of declarations from `mathlib` with docstrings similar to the given sentence. -/
meta def similar_prompts (s : string) (n : nat) : io (list declaration_with_docstring) := do
  sim_stmts ← get_similarity_prompts s n,
  sim_prompts ← sim_stmts.mmap $ λ j, io.of_except (declaration_with_docstring.from_json j),
  return sim_prompts.reverse

/-- The declarations available in the context. -/
meta def context_prompts : io (list declaration_with_docstring) := 
  io.run_tactic declaration_with_docstring.module_decls

/-- Build a prompt consisting of docstrings and theorem statements for querying Codex. -/
def build_prompt (decls : list declaration_with_docstring) : string :=
  decls.foldr (λ d prompt, d.to_full_string ++ "\n\n" ++ prompt) string.empty

/-- Produce Lean translations of a statement by querying Codex with a custom prompt -/
meta def get_translations (stmt : string) 
    (use_fixed := tt)
    (n_sim := 15) 
    (use_ctx := tt) 
    (temp := 6) 
    (n := 7) 
    (prompt_suffix := "theorem") : io (string × list string) := do
  let fix_prompts := if use_fixed then fixed_prompts else [],
  sim_prompts ← similar_prompts stmt n_sim,
  ctx_prompts ← if use_ctx then context_prompts else pure [],
  let all_prompts := sim_prompts ++ ctx_prompts,
  let main_prompt := (build_prompt all_prompts) ++ sformat!"/-- {stmt} -/\n" ++ prompt_suffix,
  
  translations ← completion_request.get_codex_completions {prompt := main_prompt, temperature := temp, n := n},
  return $ (main_prompt, translations.map (λ t, prompt_suffix ++ t))

/-- Post-process the Codex completions by converting to `declaration_with_docstring` and typechecking. -/
meta def process_translations (stmt : string)
    (use_fixed := tt) 
    (n_sim := 15) 
    (use_ctx := tt) 
    (temp := 6) 
    (n := 7) 
    (completion_prefix := "theorem") : tactic (list declaration_with_docstring × list declaration_with_docstring) := do
  (_, translations) ← tactic.unsafe_run_io $ get_translations stmt use_fixed n_sim use_ctx temp n completion_prefix,
  let translation_decls := translations.erase_dups.map $ λ t, declaration_with_docstring.from_string t stmt,
  (typecorrect_translations, failed_translations) ← translation_decls.split_with $ 
      (functor.map option.is_some) ∘ declaration_with_docstring.validate,
  return (typecorrect_translations, failed_translations)