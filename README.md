# Lean3 Statement Translation tool

A tool for automatic formalisation of natural language theorem statements to `Lean3` code using [OpenAI Codex](https://openai.com/blog/openai-codex/).

---

This is a part of [`LeanAide`](https://github.com/siddhartha-gadgil/LeanAide), which contains an autoformalisation tool using `Lean4`, among other things. A similar (but unrelated) tool also using OpenAI Codex for theorem statement autoformalisation is [`Lean Chat`](https://github.com/zhangir-azerbayev/lean-chat).

## Demonstration

![leanaide_demo](https://user-images.githubusercontent.com/18333981/204189939-dcbf639c-eefe-4e6e-bcdf-2912d641926f.gif)

## Details

The tool works best on short and self-contained theorem statements, similar to the theorem doc-strings in `mathlib`. The translation is done using *input-dependent prompting*: when the user supplies a statement to be translated, related doc-strings from `mathlib` are automatically picked up and supplied to the Codex model in the form of a "prompt".

Codex outputs a few possible translations of the input statement, which are then checked for type-correctness. Lean is a dependently-typed language, so type-checking a translation provides a strong *filter* for correctness. Moreover, as Lean exposes its internals to the user, this part can be done programmatically and efficiently from within Lean. Note that for the filtering to work as intended, the relevant imports must already be present in the file.

By default, we request `7` completions from Codex and retrieve `15` sentences from `mathlib` for input-dependent prompting. These parameters, and a few more such as temperature, can be adjusted [here](https://github.com/0art0/lean3-statement-translation-tool/blob/8a112eebc8d315b154c6fa647bf88edee67476a9/src/querying.lean#L34) and [here](https://github.com/0art0/lean3-statement-translation-tool/blob/8a112eebc8d315b154c6fa647bf88edee67476a9/src/interface.lean#L20).

In [our experiments](https://mathai2022.github.io/papers/17.pdf), we found that Codex with these modifications is able to successfully translate short docstring-like statements at the undergraduate level more than half the time.

In addition to input-dependent prompting, declarations from the same file (theorems as well as definitions) that have doc-strings are added to the Codex prompt.

The source of the prompts can influence the style and content of the translation. Translations done with input-dependent prompting with doc-strings from `mathlib` often contain the notation and terminology of `mathlib`. Likewise, when nearby declarations in the file are added to the prompt, translations may make use of definitions that are in the file but not in `mathlib`.

# Quickstart

Our translation is based on Codex, to use which you need an OpenAI key. We also use a server for *sentence similarity*. To get started please configure environment variables using the following bash commands or equivalent in your shell:

```bash
export LEANAIDE_IP="34.100.184.111:5000"
export OPENAI_API_KEY=<your-open-ai-key>
```

Clone this repository and open `src/experiments.lean` in VS Code or any other editor for Lean3. 

To translate a statement to Lean code, first type

```lean
translate? "<the statement in natural language>"
```

in the editor. A number of options for translation should appear in the infoview, highlighted in blue. Clicking on any of the options triggers a call to Codex and temporarily modifies the text in the editor. After a few seconds, a number of suggested translations should appear on the right. Clicking on a translation pastes it into the editor, replacing the text above.

To add this as a dependency to your own repository, it should suffice to add

```lean
lean3_statement_translation_tool = {git = "https://github.com/0art0/lean3-statement-translation-tool", rev = <the latest revision of the repository on GitHub>}
```

as a dependency to the `leanpkg.toml` file of your repository and build (with `leanproject build`). Then any file importing `interface.lean` should be able to run the translation tool as demonstrated above.

The above instructions should work for a normal use. Details for configuring a local set-up of the server are described in the [`README` of the `LeanAide` repository](https://github.com/siddhartha-gadgil/LeanAide/blob/main/README.md).

---
