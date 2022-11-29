import prompting

open interactive lean.parser

/--!
Provides an interface to the `translate! ` command for automatic translation of mathematical statements to Lean code.

The two-step interface is to avoid triggering the expensive tactics at every keystroke.
-/
@[user_command]
meta def translate_help (_ : parse $ tk "translate?") : lean.parser unit := do
  trace "This tool uses OpenAI Codex to turn mathematical statements in natural language to Lean code.\n\n" pure (),
  stmt ← lean.parser.pexpr,
  let s := to_string stmt,
  trace sformat!"To start translating the sentence {s} into a Lean theorem," pure (),
  suggest_string $ "translate! " ++ s,
  trace sformat!"\nTo start translating the sentence {s} into a Lean definition (not implemented)," pure (),
  suggest_string $ "translate_def! " ++ s

/-- The core function responsible for reading the string, creating the prompt, getting and processing the completions from Codex and displaying them in the infoview. -/
meta def translate_core 
  (use_fixed := tt) -- whether to use fixed prompts
  (n_sim := 15) -- the number of prompts retrieved from `mathlib` by sentence similarity
  (use_ctx := tt) -- whether to use declarations in the local context
  (temp := 6) -- the temperature setting of Codex
  (n := 7) -- the number of completions to fetch from Codex
  (prompt_suffix := "theorem") -- prompts Codex to output a `theorem`/`def`/`structure` (works best for `theorem`)
    : lean.parser unit := do
  s ← lean.parser.pexpr,
  let stmt := to_string s,
  let stmt := stmt.pop_back.pop,
  (typecorrect_translations, failed_translations) ← process_translations stmt use_fixed n_sim use_ctx temp n prompt_suffix,
  tactic.trace "\nType-correct translations:\n",
  suggest_strings $ typecorrect_translations.map declaration_with_docstring.to_full_string,
  tactic.trace "Failed translations:\n",
  suggest_strings $ failed_translations.map declaration_with_docstring.to_full_string

/--!
Translates a statement to Lean code automatically using OpenAI Codex.

This command is not meant to be used directly, but rather through the `translate?` command.
-/
@[user_command]
meta def translate_cmd (_ : parse $ tk "translate!") : lean.parser unit :=
  translate_core

/--!
Translates a statement to Lean code automatically using OpenAI Codex with **only fixed prompts**.

This command is not meant to be used directly, but rather through the `translate?` command.
-/
@[user_command]
meta def translate_fixed_cmd (_ : parse $ tk "translate₀") : lean.parser unit :=
  translate_core tt 0

/--!
A hole command that invokes the `translate!` command to automatically translate mathematical statements to Lean code.
-/
@[hole_command] meta def translate_hole_cmd : hole_command := {
  name := "translate",
  descr := "Autoformalise to Lean code",
  action := λ ps, do
    [p] ← return ps | tactic.fail "Infer command failed, the hole must contain a single term",
    let s := to_string p,
    return [("translate! " ++ s, "Translation of " ++ s)]
  }