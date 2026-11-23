# review.nvim

Review a branch from inside Neovim, with your LSP, pickers and colorscheme:

- **Review base**: `:Review develop` diffs everything against the merge-base of
  `HEAD` and `develop` (gitsigns signs and hunk actions follow it, if installed).
- **Changed files** in the quickfix list, sorted by path, tests next to their source.
- **Diff view** in two layouts, each with two modes:
  - *side-by-side*: the base version on the left, your real buffer on the right;
  - *inline*: your real buffer only, deleted lines shown in place as virtual lines;
  - `git` mode uses Neovim's diff (`'diffopt'`); `difft` mode uses
    [difftastic](https://difftastic.wilfred.me.uk/)'s structural alignment and
    highlights only the changed tokens.

  The view follows its window across files (`:cnext` etc.).
- **Persistent comments**: `[comment]` (for the PR) and `[question]` (open
  questions, e.g. for an agent), stored per branch in a markdown file outside the code.

## Requirements

- Neovim ≥ 0.11, git
- Optional: [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim), `difft`
  (the `difft` mode is silently unavailable without it; see `:checkhealth review`)

## Setup (lazy.nvim)

```lua
{
    "you/review.nvim",
    opts = {
        default_base = "develop",
        -- notes_dir = nil,              -- default: <git-common-dir>/review
        -- open_qf = "botright copen",   -- or "Trouble qflist open", or a function
        -- view = { default_mode = "git", modes = { "git", "difft" } },
        -- keymaps = false,              -- or override entries below
    },
}
```

## Commands and default keymaps

| Command | Key | |
|---|---|---|
| `:Review [base]` | | start: merge-base, gitsigns base, changed files |
| `:ReviewEnd` | | gitsigns back to the index (comments are kept) |
| `:ReviewFiles` | `<leader>rf` | changed files → quickfix |
| `:ReviewView [git\|difft\|next\|close]` | `<leader>rs` | toggle side-by-side (switches from inline) |
| `:ReviewView inline [mode]` | `<leader>ri` | toggle inline (switches from side-by-side) |
| | `<leader>rd` | difft mode in the open layout (toggle) |
| | `<leader>rm` | next mode in the open layout |
| | `<leader>rc` / `<leader>rq` | comment / question on line or visual range |
| | `<leader>rx` | delete comment under cursor |
| `:ReviewComments [kind]` | `<leader>rl` | comments → quickfix |
| `:ReviewNotes` | `<leader>rn` | open notes file, copy its path |

## Notes file

`<git-common-dir>/review/<branch>.md`, one section per comment:

````markdown
## [question] src/calc.ts:2-3

```ts
  if (x > 0) {
    return x + z;
```

why the guard?
````

Editable by hand; saving it in Neovim reloads the comments. Comments follow
edits during a session and move to the matching line if the file changed.

## Highlights

`ReviewCommentSign`, `ReviewCommentText`, `ReviewQuestionSign`,
`ReviewQuestionText`, `ReviewDifftAdd`, `ReviewDifftDelete`, `ReviewInlineAdd`,
`ReviewInlineAddText`, `ReviewInlineDelete`, `ReviewInlineDeleteText`,
`ReviewInlineDeleteNr`, `ReviewMode`,
`ReviewModeActive`. All are default links and can be overridden.
