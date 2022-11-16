import interface

section misc
  /-- Exponentiation of natural numbers. -/
  def nat.pow : ℕ → ℕ → ℕ
    | _ nat.zero := nat.succ nat.zero
    | m (nat.succ p) := m * (nat.pow m p)

  instance : has_pow ℕ ℕ := {pow := nat.pow }
end misc

translate? "Every natural number can be written as the sum of four squares."

-- translate! "There are infinitely many odd numbers."