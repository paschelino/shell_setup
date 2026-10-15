# paschelino's shell setup for MacOS

Hi, great you're here. If you like, make use of what I have put together here. For me, coming from pure bash and vim,
this was like a change from horse riding to spaceship flying. 😌 I hope this is also helpful for your daily work and
passion.

To get you started easily with nvim, here in particular with LazyVim, make use of two awesome features provided by the LazyVim distribution used here:

- `<leader>`: Open a pop up to see the next best key to press.
- `<leader>sk`: Open a search for keymappings.
- C+s for saving changes in a buffer. Yes, you did not expect that in a Vim-style editor ;-)

What does `<leader>` mean? This is the key to start a command. It is configured here to be the `<space>` key. Thus to
search for keymappings, type `<space>sk`.

## 🧐 Please note

The fact this setup works for me does not mean it works for you, too. Dotfiles are highly individual. Yet, I have tried
to optimize the combination of tools and configs and have been soaking in knowledge from multiple awesome YouTube
videos. Here are some to name a few:

- [Neovim Lua Plugin From Scratch](https://www.youtube.com/watch?v=n4Lp4cV8YR0)
- [LazyVim From Scratch To BEAST MODE](https://www.youtube.com/watch?v=evCmP4hH7ZU)

## preconditions

### Mac Package Manager

If you use MacPorts, this here won't work. Sorry. It is based on Homebrew (which will be installed in case you haven't
before).

### Rustup & Rust

Don't install `rustup` via Homebrew. It will be installed via the contained install script, to have proper use of Cargo.

### Conflicts with existing dotfiles or dotfile folders

You might run into problems with `stow`, in case some dotfiles already exist in your home directory. Best is to move
them into some backup place, before you run `./install`. A typical example is a `~/.zprofile` or `~/.zshenv` created
by the Homebrew or Rust installers: their content is already part of the `zsh` package.

## what you will install

For a detailed look on what you will install, please have a look into

- the script `./install`
- the `Brewfile`
- the `cargo_installs.sh`
- the `js-ts-global-install.sh`

On a high level after the install you will have

- NeoVim, highly configured to be a fully fledged IDE
- Ghostty, a highly modern TTY
- zsh as login shell, with vi mode, autosuggestions, syntax highlighting and carapace completions
- Nushell, a modern shell for structured data, for occasional use: run `nu` from zsh
- Starship, a shell prompt on steorids
- tmux, a massive productivity booster when you are working on multiple projects
- Rustup and Rust, to inspire you to code in Rust, but also to install awesome Rust software like nushell ;-)
- and more basic stuff that you need

## How to change things

- Please note, a dotfiles config is highly individual. Use this for creating your own dotfiles repository.

## How to install

Open your shell and run `./install` There is no guarantee that this runs through, but, as I want it to work, it is
likely...

## Dotfile management

The install script also installs the tool `stow`. It is used for symlinking the dotfile folders in this repository into
your homefolder. In case you need to run the command once manually, do it as follows:

```shell
cd <some_parent_folder>/shell_setup/dotfiles
stow --target="$HOME" <package>
```

So let's assume, you have cloned the repository into a folder like `~/projects/shell_setup` and you wish to symlink the
package ghostty:

```shell
cd ~/projects/shell_setup/dotfiles
ls
# output:
# asdf  carapace  colima  ghostty  js-ts-global  lazygit  nushell  nvim  starship  tmux  tool-versions  zk  zsh

# now run:
stow --target="$HOME" ghostty
```

### this will create a symlink looking like this

```shell
ls -la ~/.config/ghostty
# output:
# lrwxr-xr-x  1 paschelino  staff  50 Mar 22 10:00 /Users/paschelino/.config/ghostty -> ../projects/shell_setup/dotfiles/ghostty/.config/ghostty
```

## zsh

The interactive shell is zsh in vi mode: `Esc` switches to normal mode (block cursor), `v` in normal mode opens the
command line in nvim. Further helpers:

- `Ctrl-r`: fuzzy history search, `Ctrl-t`: insert a file path, `Alt-c`: cd into a subdirectory (all via fzf)
- `→`: accept the grey autosuggestion from your history
- `wt <branch>`: create a git worktree and open it in a new tmux window; `wt` alone selects an existing one

## tmux

For full developer productivity, I advise you to remap your CAPS_LOCK key to CTRL, short C. Then it is super simple to
use the according key mappings and for example to press C+a,w to open the window selector. It feels a little bit like
emacs, as every command you will be using will be preceded with C+a.

## NeoVim

It will take you some time to become familiar with nvim. Two things to ease things for you:

1. When you are inside a buffer in normal mode, you can hit the SPACE bar. It then expects to type in shortcuts to
   execute the needed commands. But after short time, it opens a pop up with the available keymappings, so that you can
   learn them slowly.
2. When you are in edit mode in a buffer and want to get back to normal mode, instead of hitting ESC, you can type short
   after another `jk`. This will enter your muscle memory very quickly and you will never want to miss it again.
3. When you want to know all capabilities available, it is best to look into the `~/.config/nvim` folder and to browse
   the plugin configs. Each of the plugin configs relates to a GitHub project where you can find more details on how to
   use those. Tools you might love the most:

- LazyGit (hit SPACE+lg)
- Toggle file explorer (hit SPACE+ee to open or SPACE+et to close it.)
- Opening or closing folders in the file explorer: Hit enter to open, hit backspace to close. Or use double clicks with
  the mouse :-D
- Open the key bindings for the file explorer: When in the file explorer hit `g?`

## JS/TS Global Packages

Global Node.js packages are managed declaratively via pnpm, similar to how Homebrew packages are managed via the Brewfile.

### Package list location

The package list lives in:
- `dotfiles/js-ts-global/.config/pnpm/global-package.json`

This file is symlinked to your home directory via `stow`, just like other dotfiles.

### Installing or updating packages

To install or update all global packages manually:

```bash
bash ./js-ts-global-install.sh
```

This script will:
- Clean up old npm-installed versions (if any)
- Install/update all packages listed in `global-package.json`
- Show you what's installed

### Adding a new global package

1. Edit `dotfiles/js-ts-global/.config/pnpm/global-package.json`
2. Add your package to the `dependencies` section:
   ```json
   "dependencies": {
     "opencode-ai": "latest",
     "your-new-package": "latest"
   }
   ```
3. Run: `bash ./js-ts-global-install.sh`

### Version pinning

You can pin specific versions or use `latest`:

```json
{
  "dependencies": {
    "opencode-ai": "latest",           // Always use latest version
    "typescript": "^5.0.0",            // Allow minor/patch updates (5.x.x)
    "some-tool": "1.2.3"               // Pin exact version
  }
}
```
