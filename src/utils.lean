import system.io

-- set_option pp.colors true

/-- Displays the input string in the Lean infoview with a "Try this: ..." message.
    Clicking on the suggestion pastes it into the editor. -/
meta def suggest_string {m : Type* → Type*} [monad m] 
    (s : string) (color : format.color := format.color.blue) : m unit :=
  let f := to_fmt sformat!"Try this: {s}\n" in
    pure $ _root_.trace_fmt (f.highlight color) (λ _, ())

run_cmd suggest_string "hello world" format.color.green

/-- A version of `suggest_string` that handles multiple strings. -/
meta def suggest_strings {m : Type* → Type*} [monad m] (l : list string) : m unit :=
  l.mmap suggest_string >>= λ _, pure ()

/-- Attempts to parse a string representing a type as an expression. -/
meta def parse_str (s : string) : tactic expr :=
  lean.parser.run $
    lean.parser.with_input interactive.types.texpr s >>=
      λ x, tactic.to_expr x.fst

run_cmd parse_str "∀ n : nat, n + n = n" >>= tactic.trace

namespace string

def pop : string → string := λ s, s.mk_iterator.next.next_to_string

def drop_while : (char → bool) → string → string
  | _ "" := ""
  | p ⟨c::cs⟩ :=
      if p c then drop_while p ⟨cs⟩ else ⟨cs⟩

end string

/-- Attempts to parse a string representing a theorem, i.e., a name, followed by a 
  sequence of arguments followed by a type which is separated by a colon. -/
meta def parse_thm_str_core : string.iterator → state nat string := λ σ, do
  n ← get,
  let c := σ.curr,

  if n = nat.zero ∧ c = ':' then
    pure sformat! "Π {σ.prev_to_string},{σ.next.next_to_string}"
  else do
    put $
      if c ∈ ['(', '[', '{', '⦃'] then
        n.succ
      else if c ∈ [')', ']', '}', '⦄'] then
        n-1
      else
        n,
    if σ.has_next then
      pure σ.next >>= parse_thm_str_core
    else
      pure σ.to_string

meta def parse_thm_str (s : string) : tactic expr :=
  let s' := s.drop_while (λ c, c ≠ ' ') in
    parse_str $ prod.fst $ (parse_thm_str_core s'.mk_iterator).run nat.zero

run_cmd parse_thm_str "test {T : Type*} (n : nat) (m : ℤ) : ↑n > m" >>= tactic.trace


namespace list

def lookup_prod {α β} : list (α × β) → (α → bool) → option β
  | [] _ := none
  | (⟨a, b⟩ :: xs) p := if p a then some b else xs.lookup_prod p

def erase_dups_aux {α} [decidable_eq α] : list α → list α → list α
  | l [] := l
  | l (a :: l') := erase_dups_aux (if a ∈ l then l else (a::l)) l'

def erase_dups_rev {α} [decidable_eq α] : list α → list α :=
  erase_dups_aux []

def erase_dups {α} [decidable_eq α] : list α → list α :=
  reverse ∘ erase_dups_rev

meta def split_with {m : Type* → Type*} {α} [monad m] : (α → m bool) → list α → m (list α × list α)
  | _ [] := return ([], [])
  | φ (a::l) := do
    v ← φ a,
    (successes, failures) ← split_with φ l,
    match v with
      | tt := return (a :: successes, failures)
      | ff := return (successes, a :: failures)
    end

end list

def except.of_option {α β} : option α → β → except β α
  | (some a) _ := except.ok a
  | none b := except.error b

namespace json

/-! The code in this section is based on similar code in `Lean Chat`. -/

meta def lookup : json → string → except string json
  | (json.object kvs) str := 
    except.of_option 
      (kvs.lookup_prod $ λ k, k = str)
      ("no key" ++ str)
  | _ _ := except.error "not an object"

meta def as_string : json → except string string
  | (json.of_string s) := except.ok s
  | _ := except.error "not a string"

meta def as_array : json → except string (list json)
  | (json.array xs) := except.ok xs
  | _ := except.error "not an array"

meta def lookup_as {α} : json → string → (json → except string α) → except string α
  | j s φ := do
    v ← j.lookup s,
    φ v

end json

meta def io.of_except {α} : except string α → io α
  | (except.ok a) := pure a
  | (except.error e) := io.fail e

meta def tactic.of_except {α} : except string α → tactic α
  | (except.ok a) := pure a
  | (except.error e) := tactic.fail e