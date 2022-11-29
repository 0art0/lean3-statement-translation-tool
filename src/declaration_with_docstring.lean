import utils

/-- A structure for storing mathematical statements together with docstrings and other relevant information. -/
structure declaration_with_docstring :=
  (is_definition : bool)
  (decl_name : string)
  (args : string)
  (type : string)
  (doc_string : string)

namespace declaration_with_docstring

/-- Retrieves a declaration from the environment by its name. -/
meta def from_name (n : name) : tactic declaration_with_docstring := do
  env ← tactic.get_env,
  decl ← env.get n,
  t ← tactic.pp decl.type,
  let stmt := to_string t,
  doc_str ← tactic.doc_string n,
  return {
    is_definition := decl.is_definition,
    decl_name := to_string n,
    args := "",
    type := stmt,
    doc_string := doc_str,
  }

/-- Retrieves all declarations with docstrings in the current module. -/
meta def module_decls : tactic (list declaration_with_docstring) := do
  mod_docs ← tactic.module_doc_strings,
  -- keep only docstrings corresponding to declarations
  let mod_docs' := mod_docs.filter_map prod.fst,
  mod_docs'.mmap from_name

/-- Checks whether a declaration is type-correct. -/
meta def validate : declaration_with_docstring → tactic (option unit)
  | ⟨_, _, args, type, _⟩ := tactic.try_core $
      let full_type := if args.is_empty then type else 
                          sformat!"Π {args}, {type}" in
        parse_str full_type >>= λ _, pure ()

/-- Convert a declaration to a `json` object. -/
meta def to_json : declaration_with_docstring → json
  | ⟨_, nm, args, type, _⟩ := 
    json.object $ [
      ("name", nm),
      ("args", args),
      ("type", type)
    ]

/-- Convert a declaration to a `json` object, including information such as the docstring. -/
meta def to_full_json : declaration_with_docstring → json
  | ⟨is_def, nm, args, type, doc_str⟩ := 
    json.object $ [
      ("is_def", json.of_bool is_def),
      ("name", nm),
      ("args", args),
      ("type", type),
      ("doc_string", doc_str)
    ]

/-- Displays a declaration as a string. -/
def to_string : declaration_with_docstring → string
  | ⟨is_def, nm, args, type, _⟩ := 
    let header :=
      (match is_def with
        | ff := "theorem"
        | tt := "def"
      end) in
    sformat!"{header} {nm}{args}:{type}"

/-- Displays a declaration and its docstring as a string. -/
def to_full_string : declaration_with_docstring → string
  | d := sformat!"/-- {d.doc_string} -/ \n {d.to_string}"

/-- The json input is assumed to be an object with all the relevant fields. -/
meta def from_json (j : json) : except string declaration_with_docstring := do
  decl_name ← j.lookup_as "name" json.as_string,
  args ← j.lookup_as "args" json.as_string,
  type ← j.lookup_as "type" json.as_string,
  doc_string ← j.lookup_as "doc_string" json.as_string,
  -- TODO: Extract `is_definition` once `defdocs` is merged
  return ⟨ff, decl_name, args, type, doc_string⟩

/-- Parses a string of the form "<theorem/def> <name> <(arg₁) (arg₂) … (argₙ)> : <type>"
    as a `declaration_with_docstring`. -/
def from_string (decl : string) (doc_str := "") : declaration_with_docstring :=
  let decl := decl.drop_while $ λ c, c.is_whitespace in
  let (decl_head, named_term) := decl.take_until $ λ c, (c.is_whitespace ∨ c = ',' ∨ c = ':' ∨ c = ';' ∨ c = '-') in
  let named_term := named_term.drop_while $ λ c, c.is_whitespace in
  let (decl_name, args_with_type) := named_term.take_until $ λ c, (c.is_whitespace ∨ c = ',' ∨ c = ':' ∨ c = ';' ∨ c = '-' ∨ c.is_left_bracket) in
  let (args, type) := process_args args_with_type in
  { is_definition := decl_head = "def", 
    decl_name := decl_name, 
    args := args.drop_while $ λ c, c.is_whitespace, 
    type := type, 
    doc_string := doc_str }

-- #eval declaration_with_docstring.args (from_string "theorem abc (n : ℕ) : n = n")

end declaration_with_docstring