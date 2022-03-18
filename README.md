# [`s3k`][]

## Synopsis

`s3k` is a script that sits between the Haskell developer and `stack`, aiming to
improve productivity when working in monorepos. The two main features are:

1. Concise package/target selections via extended regular expressions
1. Aliasing invocations

## Crash Course

For a thorough walkthrough of `s3k`, please see the [user guide](./GUIDE.md).
The snippet below is a crash course on `s3k`'s usage:

```
$ stack ide packages --stdout
bar-core
bar-server
barn
baz
foo-bar
fubar

$ s3k -b bar -p
stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-core bar-server barn foo-bar fubar

$ s3k -b '\<bar\>' -p
stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-core bar-server foo-bar

$ s3k -b '^\<bar\>' -p
stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-core bar-server

$ s3k -g '^\<(foo|bar)\>.*:lib' -p
stack ghci bar-core:lib bar-server:lib foo-bar:lib

$ s3k -g '^\<(foo|bar)\>.*:lib' -s ghci-foo-bar -p
stack ghci bar-core:lib bar-server:lib foo-bar:lib

$ s3k -a ghci-foo-bar -p
stack ghci bar-core:lib bar-server:lib foo-bar:lib

$ s3k -x 'ghcid --command "$(s3k -a ghci-foo-bar -p)"' -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"

$ s3k -x 'ghcid --command "$(s3k -a ghci-foo-bar -p)"' -s ghcid-foo-bar -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"

$ s3k -a ghcid-foo-bar -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"
```

There is a strong emphasis on ensuring the dev has to type as little as
possible. Please see the [Goals](#goals) section for additional detail.

## Installation

### Manual install

`s3k` is a single `bash` script and an optional completion script, so
installation is pretty straightforward:

1. Ensure [`jq`][] and [`stack`][] are installed and available on your runtime
   path:
   ```
   $ command -v jq &>/dev/null || echo "jq is not on runtime path" >&2
   $ command -v stack &>/dev/null || echo "stack is not on runtime path" >&2
   ```
   If you prefer not having these tools on your runtime path, you may tell `s3k`
   where they are on your system via the `S3K_PATH_JQ` and `S3K_PATH_STACK`
   environment variables.
1. Clone the repo:
   ```
   git clone https://github.com/jship/s3k.git
   ```
   If you'd like to hack on `s3k`, feel free to fork and then clone your fork
   instead.
1. Edit your runtime path (in `~/.bashrc`, `~/.bash_profile`, or wherever makes
   sense on your system) to include the repo's `bin` directory:
   ```
   export PATH="$PATH:/path/to/s3k/bin"
   ```
1. _Optional:_ Install the completion script.
   TODO: STUB

If, like the author, you find that even `s3k` is too many characters to type,
you may wish to add an alias to your system:

```
alias s='s3k'
```

`s3k` has been tested predominantly on `bash` version 5.1. The script is written
somewhat carefully such that it should be compatible with `bash` 3.2 and onward.
If you are running a version older than 3.2 and the script works for you, please
feel free to update this README to indicate as such. There are no plans
currently to formally support versions older than 3.2.

### Install via package manager

At this time, there is no support for installing `s3k` via package managers.
Fortunately, it is only a single `bash` script plus an optional completion
script, and so can be [installed manually](#manual-install) with minimal fuss.

If you would like to add support for installing `s3k` via a particular package
manager, please feel free to reach out and contribute!

## Goals

The primary goal in the creation of `s3k` is that the developer should have to
type as little as possible to interact with their projects. This is achieved
through filtering the packages for build, test, GHCi, and so on via
developer-specified extended regular expressions. Fortunately, most regexes a
developer would reach for to filter Haskell packages are not overly complicated.
Even if the developer has not yet used regexes before, the script and associated
docs aim to provide sufficient examples so that everyone can be productive right
away.

Most developers do not yearn to conjure up regexes every time they need to
interact with some slice of a monorepo though, and `s3k` would be inhumane if it
expected them to do so. For this reason, `s3k` heavily encourages aliasing
commands. The developer can type in their desired regex, save it away in an
alias, and then never think about the regex again.

[`s3k`]: https://github.com/jship/s3k
[`jq`]: https://stedolan.github.io/jq/download/
[`stack`]: https://docs.haskellstack.org/en/stable/install_and_upgrade/
