# [`s3k` User Guide][]

## Intro

This user guide provides a walkthrough of usage of `s3k`. The guide is split
into sections for navigation convenience, but is written as one start-to-finish
document. It is intended to be interactive, so if you'd like to run all the
demonstrated commands throughout this guide, you can generate the companion
monorepo via:

```
$ cd /path/to/s3k/repo
$ test/s3kTests -m
```

There will now be a monorepo suitable for testing `s3k` under `test/monorepo`.
Let's take a look at the packages in this monorepo:

```
$ cd test/monorepo
$ stack ide packages --stdout
bar-api
bar-client
bar-core
bar-server
barn
foo-bar
foo-bar-baz
foo-core
fubar
```

We have nine packages to work with. Let's see what targets are available from
these packages (understanding the following `awk` invocation is not important
for this guide - it just gives us some nicer output to look at):

```
$ stack ide targets --stdout | awk -F ':' '
{
  target_type = $2
  if (! line_group[$1])
    line_group[$1] = target_type
  else
    line_group[$1] = line_group[$1] "\t" target_type
}
END {
  for (i in line_group)
    printf "%s\t%s\n", i, line_group[i]
}' | sort | column -t
bar-api      lib  test
bar-client   lib  test
bar-core     lib
bar-server   lib  exe   test   bench
barn         lib  test  bench
foo-bar      lib  test
foo-bar-baz  lib  test  bench
foo-core     lib
fubar        lib  exe   test   bench
```

We have:

* Two packages that only have library targets
* Three packages that have library and test targets
* Two packages that have library, test, and benchmark targets
* Two packages that have library, test, benchmark, and executable targets

Amongst these nine packages, we have two "package suites": `bar` and `foo`. In
this guide, we refer to a "package suite" as a set of packages all with the same
prefix immediately followed by a hyphen.

## Full builds (with regex intro)

Let's start off by fully building the `bar` package suite without using `s3k`:

```
$ stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-api bar-client bar-core bar-server
```

That was quite a bit to type. We might already be toying with the idea of
shoving the above invocation into a script. Let's see if we can have `s3k` save
us some effort:

```
$ s3k -b bar -p
stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-api bar-client bar-core bar-server barn foo-bar foo-bar-baz fubar
```

_Aside:_ The `-p` flag is one of the most important `s3k` flags to internalize.
It stands for "print" and does exactly what it says on the tin: `-p` will make
`s3k` print the command it generates rather than execute it. We will soon see
how valuable this flag is, as it lets us iteratively build up an `s3k`
invocation without actually carrying out expensive `stack build` operations.

Our first use of `s3k` built a few extra packages that aren't part of the `bar`
package suite: `barn`, `foo-bar`, `foo-bar-baz`, and `fubar`. Let's work towards
refining our `s3k` invocation with an extended regex:

```
$ s3k -b '\<bar\>' -p
stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-api bar-client bar-core bar-server foo-bar foo-bar-baz
```

We're getting closer to what we're after, but not quite there just yet. Note
that the `\<bar\>` regex means "match `bar` as a whole word". The `\<` and `\>`
are known as word boundaries and they indicate that there should not be any
additional word characters immediately preceding or following `bar`. Having a
whole-word match on `bar` means we've pruned away `barn` and `fubar` from the
packages we wish to build.

When in doubt, add more regex! (said no one ever)

```
$ s3k -b '^\<bar\>' -p
stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-api bar-client bar-core bar-server
```

Hurray! Now we have a concise way of building just the `bar` package suite. You
can lop off the `-p` option if you'd like to go through with the build.

The only new piece of regex we introduced was `^`, which is known as a line
anchor.  `^` indicates that the pattern following must appear at the start of
the line.  Under the hood, `s3k` is passing the available package targets, each
on their own line, to a `grep -E` invocation. We exploit this fact in our regex.

## Build/test/haddock/benchmark/GHCi/run

Let's try this same regex but we'll swap out `-b` for some of the other relevant
options:

```
$ s3k -B '^\<bar\>' -p
stack build --pedantic bar-api bar-client bar-core bar-server

$ s3k -t '^\<bar\>' -p
stack test --pedantic bar-api bar-client bar-server

$ s3k -k '^\<bar\>' -p
stack haddock --pedantic bar-api bar-client bar-core bar-server

$ s3k -m '^\<bar\>' -p
stack bench --pedantic bar-server

$ s3k -g '^\<bar\>' -p
stack ghci bar-api:lib bar-api:test:bar-api-test-suite bar-client:lib bar-client:test:bar-client-test-suite bar-core:lib bar-server:bench:bar-server-bench-suite bar-server:exe:bar-server-exe bar-server:lib bar-server:test:bar-server-test-suite

$ s3k -r '^\<bar\>' -p
stack run bar-server-exe
```

The invocations containing `-t` (short for `stack test`) and `-m` (short for
`stack bench`) are (mildly) interesting in that `s3k` takes into account whether
or not test/bench targets exist in the first place. That is why we don't see the
full package suite on those lines.

Let's see what happens if we use a couple of these options we've seen, but in
one shot:

```
$ s3k -B '^\<bar\>' -t '^\<bar\>' -p
stack build --pedantic bar-api bar-client bar-core bar-server && stack test --pedantic bar-api bar-client bar-server
```

`s3k` has generated a command list for us, where each command is joined together
with `&&`.

Perhaps we'd like to do the same thing as above, but without concern for
warnings:

```
$ s3k -B '^\<bar\>' -t '^\<bar\>' -p -W
stack build bar-api bar-client bar-core bar-server && stack test bar-api bar-client bar-server
```

Note that for each of the build-adjacent options we've seen thus far - `-t`,
`-k`, `-m`, and `-g` - you can pass the same option but with a capital letter to
funnel along arguments:

```
$ s3k -t 'bar-server' -T '--match "Bar.Server"' -p
stack test --pedantic --test-arguments '--match "Bar.Server"' bar-server

$ s3k -k 'bar-server' -K '--html --pretty-html' -p
stack haddock --pedantic --haddock-arguments '--html --pretty-html' bar-server

$ s3k -m 'bar-server' -M '--match pattern "bar_server"' -p
stack bench --pedantic --benchmark-arguments '--match pattern "bar_server"' bar-server

$ s3k -g 'bar-server:lib' -G '-cpp' -p
stack ghci --ghci-options '-cpp' bar-server:lib

$ s3k -r 'bar-server-exe' -R '--do-stuff --do-other-stuff' -p
stack run bar-server-exe -- --do-stuff --do-other-stuff
```

## Raw stack arguments

We can also pass raw `stack` arguments by delimiting `s3k`'s options and
`stack`'s arguments with `--`:

```
$ s3k -B '^\<bar\>' -p -- --dry-run
stack build --pedantic --dry-run bar-api bar-client bar-core bar-server
```

This suggests that we can also use `s3k` as a direct wrapper for `stack`, just
one that is two characters shorter to type (or even shorter if you're on the
system alias train!):

```
$ s3k -p -- build --pedantic --dry-run bar-api bar-client bar-core bar-server
stack build --pedantic --dry-run bar-api bar-client bar-core bar-server
```

Note that raw stack arguments are passed to _all_ generated commands, so they
should be used with care if the command you are generating via `s3k` is a
command list:

```
$ s3k -B 'bar-server' -t 'bar-server' -W -p -- --test-arguments '--match "Whoopsie!"'
stack build --test-arguments --match "Whoopsie!" bar-server && stack test --test-arguments --match "Whoopsie!" bar-server
```

The above example is a bit contrived, as we should always prefer using the `-T`
option to `s3k` rather than specifying the raw `--test-arguments` stack
argument, but hopefully it gets the point across that stack arguments are
distributed to each command in the final command list. This functionality can be
very useful, e.g. for options like `--resolver`, `--stack-yaml`, etc.

## Environment variables

We can set environment variables that are local to an `s3k` invocation via the
`-e` option:

```
$ s3k -r bar-server-exe -e PORT=7890 -e LOGGING=verbose -p
( export LOGGING='verbose'; export PORT='7890'; stack run bar-server-exe )
```

`s3k` made a subshell for us where the environment variables are exported and
then our generated command runs. The use of a subshell here makes it so that if
our generated command is actually a list of commands (delimited by `&&`), each
command will have the environment variables available.

Note that the above example is equivalent to the following:

```
$ PORT=7890 LOGGING=verbose s3k -r bar-server-exe -p
```

However, if we choose to explicitly tell `s3k` about the environment variables
via `-e`, then we can save these environment variables in our `s3k` aliases.

## Aliasing

Typing regexes any time we want to interact with our build tool doesn't exactly
spark joy. This is where aliases come in.

Before we do alias things, let's look at a couple more regex features we haven't
seen yet:

```
$ s3k -g '^\<(foo|bar)\>.*:lib' -p
stack ghci bar-api:lib bar-client:lib bar-core:lib bar-server:lib foo-bar-baz:lib foo-bar:lib foo-core:lib
```

A good chunk of this regex is the same: we want to do stuff with the `bar`
package suite. But we're now using regex alternation so that we also do stuff
with the `foo` package suite. `(foo|bar)` means "match `foo` or `bar`". The
pattern provided to `-g` is run against all of the monorepo's _targets_ (not its
packages), so we are careful to say "match only the library targets" via
`.*:lib`. The `.` means "match any character" and `*` means "for the immediately
preceding match, expect this same match 0 or more times". The `:lib`, just
like `foo`, `bar`, etc. means "match `:lib` exactly".

All of the above is to say: we want to run GHCi with the library targets of the
`foo` and `bar` package suites.

Having typed that regex the one time, I'd much prefer never typing it again.
Let's save it to an alias with the `-s` option:

```
$ s3k -g '^\<(foo|bar)\>.*:lib' -s ghci-foo-bar -p
stack ghci bar-api:lib bar-client:lib bar-core:lib bar-server:lib foo-bar-baz:lib foo-bar:lib foo-core:lib
```

Now we can recall this alias via the `-a` option:

```
$ s3k -a ghci-foo-bar -p
stack ghci bar-api:lib bar-client:lib bar-core:lib bar-server:lib foo-bar-baz:lib foo-bar:lib foo-core:lib
```

The `s3k` completion script will tab-complete aliases for you, so no need to
worry on remembering them exactly.

Multiple aliases can be recalled in a single `s3k` invocation:

```
$ s3k -B '^\<foo\>' -s build-foo -p
stack build --pedantic foo-bar foo-bar-baz foo-core

$ s3k -B '^\<bar\>' -s build-bar -p
stack build --pedantic bar-api bar-client bar-core bar-server

$ s3k -t '^\<bar\>' -s test-bar -p
stack test --pedantic bar-api bar-client bar-server

$ s3k -a build-foo -a build-bar -a test-bar -p
stack build --pedantic bar-api bar-client bar-core bar-server foo-bar foo-bar-baz foo-core && stack test --pedantic bar-api bar-client bar-server
```

Note that when an invocation is saved to an alias, `-W` is not saved with it.
This makes combining aliases much more convenient.

As we've seen, `-s` saves an alias. But there is also `-S`. The difference is
that `-s` saves a project-specific alias, while `-S` saves a "global" alias.
Global aliases can be useful when you want to leverage the same `s3k` invocation
across multiple `stack` projects.

We can delete project-specific aliases via `-d` and global aliases via `-D`.

## Custom commands

Custom commands can be run via the `-x` option:

```
$ s3k -x 'ls -l' -p
ls -l
```

This is particularly useful to invoke `ghcid`:

```
$ s3k -x 'ghcid --command "$(s3k -a ghci-foo-bar -p)"' -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"
```

In the above invocation, we've defined our custom command such that if we were
to execute it (by removing the trailing `-p`), `s3k` calls itself to populate
`ghcid`'s `--command` option by loading the `ghci-foo-bar` alias.

Note that the quoting is critical: we wrap the whole custom command in
single-quotes, not unlike how we've been writing our regexes in single-quotes.
With the whole custom command in single-quotes, the inner `s3k` invocation will
not be expanded by our shell, so our outer `s3k` invocation will receive the
text exactly as we've written it (`ghcid --command "$(s3k -a ghci-foo-bar -p)"`)
rather than the expansion (`stack ghci bar-api:lib bar-client:lib ...`).

It's likely unsurprising at this point, but we can capture the above command in
its own alias:

```
$ s3k -x 'ghcid --command "$(s3k -a ghci-foo-bar -p)"' -s ghcid-foo-bar -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"

$ s3k -a ghcid-foo-bar -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"
```

Now we can freely update our `ghci-foo-bar` alias as needed, and we
automatically get those updates when using our `ghcid-foo-bar` alias because the
`ghcid` alias is defined in terms of the `ghci` alias.

**Caution:** If you typically invoke `s3k` via a system alias, do not use the
system alias in "embedded" `s3k` invocations. For example, if you have `s` as a
system alias for `s3k`:

```
# Right
$ s -x 'ghcid --command "$(s3k -a ghci-foo-bar -p)"' -s ghcid-foo-bar -p
ghcid --command "$(s3k -a ghci-foo-bar -p)"

# Wrong
$ s -x 'ghcid --command "$(s -a ghci-foo-bar -p)"' -s ghcid-foo-bar -p
```

If `-x` is present along with any other command-generating option (`-b`, `-B`,
`-t`, `-k`, and `-m`), then the custom command will be run at the end of the
command list:

```
$ s3k -a build-bar -x 'open https://youtu.be/dQw4w9WgXcQ' -p
stack build --pedantic bar-api bar-client bar-core bar-server && open https://youtu.be/dQw4w9WgXcQ
```

This can be useful if you'd like to do some cleanup (e.g. deleting `hspec`
files), be alerted when a build is done, etc.

Our custom command can itself be a command list, pipeline, etc.:

```
$ s3k -x 'find . -name package.yaml -type f -print | wc -l' -p
find . -name package.yaml -type f -print | wc -l
```

## Config file

Considering `s3k` supports saving aliases, these aliases have to be saved
somewhere. They are saved to `s3k`'s config file. By default, this config file
will be at `${XDG_CONFIG_HOME}/s3k/config.json` if the `XDG_CONFIG_HOME`
environment variable is populated. Otherwise, the config file will be at
`"${HOME}/.s3k/config.json"`. The user is free to override the directory in
which `s3k` will write its config file via the `S3K_CONFIG_HOME` environment
variable.

If you'd like to view or update the config file manually, you can get the file
path via `s3k -c`. In general, you should opt for `s3k` itself to be the sole
editor of the config file, but as long as you're careful, edit away!

## Caching

If the monorepo we're working on is big enough, `stack ide packages` and `stack
ide targets` are noticeably slow commands. The output from these commands
underpin most operations with `s3k`, so `s3k` does project-specific caching of
the output from these commands. The cache for a project will be automatically
generated if not present.

We can tell `s3k` to regenerate a project's cache via running `s3k -C` from any
directory at or under our `stack` project. You should only need to run this
command when packages are added to or deleted from your monorepo, or when the
available targets of an existing package change. A habit I've developed is to
consider running `s3k -C` whenever I sync a repo's `main` branch into my local
branch.

## End

If you've made it this far, you know just about everything there is to know
about using `s3k`.

Now go forth and type less!

[`s3k` User Guide]: https://github.com/jship/s3k/blob/main/GUIDE.md
