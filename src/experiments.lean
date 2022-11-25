import interface

-- UI Demo

section demo
-- translate! "There are infinitely many odd numbers."

/-- There are infinitely many odd numbers. -/
theorem inf_odds : ∀ n : ℕ, ∃ m : ℕ, m > n ∧ m % 2 = 1 := sorry

/-- A prime is a number that is divisible only by `1` and itself. -/
def my_prime_number (p : ℕ) := ∀ n : ℕ, p % n = 0 → n = 1 ∨ n = p

/-- `2` is a prime number. -/
theorem two_prime : my_prime_number 2 := sorry

translate? "There are infinitely many primes that are one greater than a multiple of four."

end demo