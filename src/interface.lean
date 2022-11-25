import prompting

open interactive lean.parser

/--!
Provides an interface to the `translate ` and `translate/` commands for automatic translation of mathematical statements to Lean code.

The two-step interface is to avoid triggering the expensive tactics at every keystroke.
-/
@[user_command]
meta def translate_help (_ : parse $ tk "translate?") : lean.parser unit := do
  trace "This tool uses OpenAI Codex to turn mathematical statements in natural language to Lean code.\n\n" pure (),
  stmt ← lean.parser.pexpr,
  let s := to_string stmt,
  trace sformat!"To start translating the sentence {s} into a Lean theorem," pure (),
  suggest_string $ "translate! " ++ s,
  trace sformat!"To start translating the sentence {s} into a Lean theorem using Lean Chat prompts (not implemented)," pure (),
  suggest_string $ "translate₀ " ++ s,
  trace sformat!"\nTo start translating the sentence {s} into a Lean definition (not implemented)," pure (),
  suggest_string $ "translate/ " ++ s

/--!
Translates a statement to Lean code automatically using OpenAI Codex.

This command is not meant to be used directly, but rather through the `translate?` command.
-/
@[user_command]
meta def translate_cmd (_ : parse $ tk "translate!") : lean.parser unit := do
  s ← lean.parser.pexpr,
  let stmt := to_string s,
  let stmt := stmt.pop_back.pop,
  (typecorrect_translations, failed_translations) ← process_translations stmt,
  tactic.trace "\nType-correct translations:\n",
  suggest_strings $ typecorrect_translations.map declaration_with_docstring.to_full_string,
  tactic.trace "Failed translations:\n",
  suggest_strings $ failed_translations.map declaration_with_docstring.to_full_string

/--!
A hole command that invokes the `translate` command to automatically translate mathematical statements to Lean code.
-/
@[hole_command] meta def translate_hole_cmd : hole_command := {
  name := "translate",
  descr := "Autoformalise to Lean code",
  action := λ ps, do
    [p] ← return ps | tactic.fail "Infer command failed, the hole must contain a single term",
    let s := to_string p,
    return [("translate " ++ s, "Translation of " ++ s), ("translate/ " ++ s, "Translation of " ++ s ++ " with docstring")]
  }