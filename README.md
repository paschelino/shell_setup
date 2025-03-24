# paschelino's shell setup
Hi, great you're here. If you like, make use of what I have put together here. For me, coming from pure bash and vim, 
this was like a change from horse riding to spaceship flying. 😌 I hope this is also helpful for your daily work and passion.

## 🧐 Please note: 
The fact this setup works for me does not mean it works for you, too. Dotfiles are highly individual.
Yet, I have tried to optimize the combination of tools and configs and have been soaking in knowledge from multiple awesome
YouTube videos. Here are some to name a few:
-  

## preconditions:
### Mac Package Manager
If you use MacPorts, this here won't work. Sorry. It is based on Homebrew (which will be installed in case you haven't before).

### Rustup & Rust
Don't install `rustup` via Homebrew. It will be installed via the contained install script, to have proper use of Cargo.

### Conflicts with existing dotfiles or dotfile folders
You might run into problems with `stow`, in case some dotfiles already exist in your home directory. 
Best is to move them into some backup place, before you run `./install`.

## what you will install:
For a detailed look on what you will install, please have a look into
- the script `./install`
- the `Brewfile`
- the `cargo_installs.sh`

On a high level after the install you will have
- NeoVim, highly configured to be a fully fledged IDE
- Ghostty, a highly modern TTY
- Nushell, a (non POSIX compliant) modern extreme awesome DevUX shell
- Starship, a shell prompt on steorids
- tmux, a massive productivity booster when you are working on multiple projects
- Rustup and Rust, to inspire you to code in Rust, but also to install awesome Rust software like nushell ;-)
- and more basic stuff that you need

## How to change things
- Please note, a dotfiles config is highly individual. Use this for creating your own dotfiles repository.

## How to install:
Open your shell and run `./install`
There is no guarantee that this runs through, but, as I want it to work, it is likely...

## Dotfile management:
The install script also installs the tool `stow`. It is used for symlinking the dotfile folders in this repository
into your homefolder. In case you need to run the command once manually, do it as follows:
```shell
cd <some_parent_folder>/shell_setup/dotfiles
stow --target="$HOME" <package>
```

So let's assume, you have cloned the repository into a folder like `~/projects/shell_setup` and you wish to symlink the package ghostty:
```shell
cd ~/projects/shell_setup
ls
# output:
╭───┬──────────┬──────┬──────┬──────────────╮
│ # │   name   │ type │ size │   modified   │
├───┼──────────┼──────┼──────┼──────────────┤
│ 0 │ ghostty  │ dir  │ 96 B │ 6 hours ago  │
│ 1 │ nushell  │ dir  │ 96 B │ 6 hours ago  │
│ 2 │ nvim     │ dir  │ 96 B │ 6 hours ago  │
│ 3 │ personal │ dir  │ 96 B │ 7 months ago │
│ 4 │ starship │ dir  │ 96 B │ 6 hours ago  │
│ 5 │ tmux     │ dir  │ 96 B │ 6 hours ago  │
╰───┴──────────┴──────┴──────┴──────────────╯

# now run:
stow --target="$HOME" ghostty

# this will create a symlink looking like this:
ls -la ~/.config
# output:
╭────┬─────────────────────────────────────────┬─────────┬────────────────────────────────────────────────────────────┬─...
│  # │                  name                   │  type   │                           target                           │
├────┼─────────────────────────────────────────┼─────────┼────────────────────────────────────────────────────────────┼─...
│  0 │ /Users/paschelino/.config/carapace      │ dir     │                                                            │
│  1 │ /Users/paschelino/.config/gem           │ dir     │                                                            │
│  2 │ /Users/paschelino/.config/gh            │ dir     │                                                            │
│  3 │ /Users/paschelino/.config/ghostty       │ symlink │ ../dev/shell_setup/dotfiles/ghostty/.config/ghostty        │
│  4 │ /Users/paschelino/.config/iterm2        │ dir     │                                                            │
│  5 │ /Users/paschelino/.config/nushell       │ symlink │ ../dev/shell_setup/dotfiles/nushell/.config/nushell        │
│  6 │ /Users/paschelino/.config/nvim          │ symlink │ ../dev/shell_setup/dotfiles/nvim/.config/nvim              │
│  7 │ /Users/paschelino/.config/starship.toml │ symlink │ ../dev/shell_setup/dotfiles/starship/.config/starship.toml │
│  8 │ /Users/paschelino/.config/yaari         │ dir     │                                                            │
╰────┴─────────────────────────────────────────┴─────────┴────────────────────────────────────────────────────────────┴─...
```

