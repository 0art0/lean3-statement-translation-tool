# Lean3 Statement Translation tool

A tool for automatic formalisation of natural language theorem statements to `Lean3` code using [OpenAI Codex](https://openai.com/blog/openai-codex/).

---

This is a part of [`LeanAide`](https://github.com/siddhartha-gadgil/LeanAide), which contains an autoformalisation tool using `Lean4`, among other things. A similar (but unrelated) tool also using OpenAI Codex for theorem statement autoformalisation is [`Lean Chat`](https://github.com/zhangir-azerbayev/lean-chat).

## Details

The tool works best on short and self-contained theorem statements, similar to the theorem doc-strings in `mathlib`. The translation is done using *input-dependent prompting*: when the user supplies a statement to be translated, related doc-strings from `mathlib` are automatically picked up and supplied to the Codex model in the form of a "prompt".

Codex outputs a few possible translations of the input statement, which are then checked for type-correctness. Lean is a dependently-typed language, so type-checking a translation provides a strong *filter* for correctness. Moreover, as Lean exposes its internals to the user, this part can be done programmatically and efficiently from within Lean. Note that for the filtering to work as intended, the relevant imports must already be present in the file.

In [our experiments](https://mathai2022.github.io/papers/17.pdf), we found that Codex with these modifications is able to successfully translate short docstring-like statements at the undergraduate level more than half the time.

In addition to input-dependent prompting, declarations from the same file (theorems as well as definitions) that have doc-strings are added to the Codex prompt. 

# Quickstart

Our translation is based on Codex, to use which you need an OpenAI key. We also use a server for *sentence similarity*. To get started please configure environment variables using the following bash commands or equivalent in your shell:

```bash
export LEANAIDE_IP="34.100.184.111:5000"
export OPENAI_API_KEY=<your-open-ai-key>
```

This step is needed only once.

Clone this repository and open `src/experiments.lean` in VS Code or any other editor for Lean3. 

To translate a statement, such as "Every natural number can be written as the sum of four squares", to Lean code, first type

```lean
translate? "Every natural number can be written as the sum of four squares"
```

in the editor. A number of options highlighted in blue should appear in the infoview. Clicking on any of the options triggers a call to Codex and temporarily modifies the text in the editor. After a few seconds, a number of suggested translations should appear on the right. Clicking on a translation pastes it into the editor, replacing the text above.

To add this as a dependency to your own repository, it should suffice to add

```lean
lean3_statement_translation_tool = {git = "https://github.com/0art0/lean3_statement_translation_tool", rev = <the latest revision of the repository on GitHub>}
```

Then any file importing `interface.lean` should be able to run the translation tool as demonstrated above.

The above instructions should work for a normal use. Details for configuring a local set-up of the server are described in the [`README` of the `LeanAide` repository](https://github.com/siddhartha-gadgil/LeanAide/blob/main/README.md).

---