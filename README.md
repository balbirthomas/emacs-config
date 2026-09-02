# Emacs configuration

This directory holds a personal Emacs configuration, split into one file per
concern and loaded by `~/.emacs`. It contains no personal information
(name, email, IRC login, local install paths) — those are read from
environment variables at startup, so the same files work for anyone.

## Setup

1. Put this directory at `~/.emacs.d/lisp/` and use (or merge in) the loader
   below as `~/.emacs`:

   ```elisp
   (setq load-path (append load-path (list (expand-file-name "lisp" user-emacs-directory))))

   ;; GUI/session-managed Emacs instances don't source ~/.bashrc or
   ;; ~/.profile, so they miss the environment variables below unless
   ;; imported explicitly. Must run before `mail' (or anything else that
   ;; reads them) -- see step 2.
   (require 'exec-path-from-shell)
   (dolist (var '("EMAIL_NAME" "EMAIL_ADDRESS" "GNUS_NNTP_SERVER"
                  "IRCSERVER" "IRCNICK" "SAGE_ROOT"))
     (add-to-list 'exec-path-from-shell-variables var))
   (exec-path-from-shell-initialize)

   (require 'mail)
   (require 'browser)
   (require 'editing)
   (require 'init-erc)
   (require 'utility)
   (require 'packages)
   (require 'init-org)
   (require 'languages)
   (require 'init-custom)
   ```

2. Set the environment variables below in your shell's startup files (e.g.
   `~/.bash_exports`, sourced from `~/.bashrc`) **before** starting Emacs.
   Emacs only sees environment variables that were set in the environment
   it was launched from — if you launch Emacs from a desktop/app launcher
   rather than a terminal, that environment may not include your shell's
   exports at all, even though a terminal-launched Emacs would see them
   fine. The loader above already imports them via `exec-path-from-shell`
   (a real dependency now, not just an available package) to cover that
   case; it needs the package installed (`M-x package-install RET
   exec-path-from-shell RET`, or your distro's `elpa-exec-path-from-shell`)
   and, on macOS/Linux, does spawn one interactive shell at startup to read
   them, which costs a second or so.

3. Add matching entries to `~/.authinfo` (mode `600` or `640`) for whichever
   of mail/Usenet/IRC you use — see "Credentials" below.

## Environment variables

| Variable | Used for | If unset |
|---|---|---|
| `EMAIL_NAME` | `user-full-name` (mail identity) and ERC's realname field | Left `nil`; a warning is printed at startup |
| `EMAIL_ADDRESS` | `user-mail-address` | Left `nil`; a warning is printed at startup. **Also breaks `C-c C-e h o` (Org HTML export)** — Org's `org-html-format-spec` does an unguarded `split-string` on it while building the preamble, so a `nil` `user-mail-address` throws `(wrong-type-argument stringp nil)` on every HTML export, not just a warning |
| `GNUS_NNTP_SERVER` | Gnus's Usenet (NNTP) server | Defaults to `news.eternal-september.org` |
| `IRCNICK` | ERC nickname, and the `auth-source` login used to find your NickServ password | Falls back to your OS login name (`user-login-name`), so connecting never fails outright |
| `IRCSERVER` | ERC server, used by `M-x erc-connect` / `C-c e f` | Defaults to `irc.libera.chat` |
| `SAGE_ROOT` | SageMath install root; the executable is derived as `$SAGE_ROOT/bin/sage` | A warning is printed; sage-shell-mode's own defaults apply |

None of these are read directly from `~/.authinfo` or hardcoded elsewhere in
this directory — `grep -rn getenv-or-warn *.el` in this directory finds every
place personal configuration is read.

**Not parameterized, by design:**
- The mail SMTP/IMAP hosts (`mail.el`) are hardcoded to Gmail's servers.
  Supporting other providers means more than swapping a hostname (ports,
  auth mechanism, TLS setup all differ), so if you use a different provider,
  edit `mail.el` directly.
- Julia (`init-org.el`) is invoked as plain `"julia"` and resolved via your
  shell's `PATH` — no environment variable needed, just make sure `julia` is
  on `PATH`.

## Credentials

Real secrets (passwords) are never read from environment variables or
stored in this directory — they live in `~/.authinfo` (netrc format), read
via Emacs's `auth-source`. Example, matching the environment variables
above:

```
machine smtp.gmail.com login YOUR_EMAIL_ADDRESS password YOUR_APP_PASSWORD port 587
machine imap.gmail.com login YOUR_EMAIL_ADDRESS password YOUR_APP_PASSWORD port imaps
machine YOUR_GNUS_NNTP_SERVER login YOUR_NNTP_USERNAME password YOUR_NNTP_PASSWORD
machine YOUR_IRCSERVER login YOUR_IRCNICK password YOUR_NICKSERV_PASSWORD
```

The `machine`/`login` fields must match whatever you set `GNUS_NNTP_SERVER`/
`IRCSERVER`/`IRCNICK`/`EMAIL_ADDRESS` to, since that's what `auth-source`
matches against at connection time.

## Layout

Each file is a self-contained `provide`/`require` unit; see its own
`;;; Commentary:` header for what it configures. Three files keep an
`init-` prefix on their filename (`init-org.el`, `init-erc.el`,
`init-custom.el`) because their bare names (`org`, `erc`, `custom`) are
real, already-loaded Emacs/ELPA libraries — a same-named file here would
either shadow the real one or never be reached, depending on load-path
order. Every other file dropped the prefix as unnecessary.

Per-language setup lives in `lang-*.el`, loaded by `languages.el`. One of
these, `lang-markdown.el`, has a `pandoc-filters/` subdirectory alongside
it — the only non-Lisp assets here — holding a Pandoc Lua filter and a
LaTeX header file it shells out to for Markdown's HTML/PDF export. See
that file's Commentary for how the pieces fit together (requires
`pandoc`, `xelatex`, and `dvisvgm` on `exec-path`).

To add
support for another compiled language (build/run/clean/distclean via
`M-n C-c C-b/C-r/C-c/C-d`, from `utility.el`'s `compiled-program-bind-keys`
and `run-make-target`): write a makefile with `build`/`run`/`clean`/
`distclean` targets driven by `PROGRAM`/`EXT` variables (see
`work/src/fortran/makefile` for the model), then add a file like:

```elisp
(with-eval-after-load 'FEATURE
  (compiled-program-bind-keys SOME-MODE-MAP))
```

## Optional features (off by default)

Three things are disabled unless you turn them on, so default behavior is
unaffected by their presence:

- `M-x toggle-eaf` — EAF (Emacs Application Framework) + eaf-jupyter.
- `M-x toggle-comint-mime` — inline rich output in shell/Python buffers.
- `M-x toggle-python-interpreter` — switch between Python and IPython for
  new `run-python` shells (Python is the default).

All three are `defcustom`s under Emacs's standard `local` customize group
(`M-x customize-group RET local RET`) if you'd rather set them permanently
than toggle per session.
