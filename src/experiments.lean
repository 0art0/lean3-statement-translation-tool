import interface

section misc
  /-- Exponentiation of natural numbers. -/
  def nat.pow : ℕ → ℕ → ℕ
    | _ nat.zero := nat.succ nat.zero
    | m (nat.succ p) := m * (nat.pow m p)

  instance : has_pow ℕ ℕ := {pow := nat.pow }
end misc

-- UI Demo


/-
section demo
-- translate! "There are infinitely many odd numbers."


/-- A prime is a number that is divisible only by `1` and itself. -/
def my_prime_number (p : ℕ) := ∀ n : ℕ, p % n = 0 → n = 1 ∨ n = p

/-- `2` is a prime number. -/
theorem two_prime : my_prime_number 2 := sorry

translate? "There are infinitely many primes that are one greater than a multiple of four."

end demo
-/

/-!
# Features:
- Input-dependent prompting
- Filtering by type-checking
- Context-specific prompting
- Integration with the editor
- Definition translation (work in progress)
-/
