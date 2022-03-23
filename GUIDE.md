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
* Two pacakges that have library, test, and benchmark targets
* Two packages that have library, test, benchmark, and executable targets

Amongst these nine packages, we have two "package suites": `bar` and `foo`. In
this guide, we refer to a "package suite" as a set of packages all with the same
prefix immediately followed by a hyphen.

## Full builds (with regex intro)

Let's start off by fully building the `bar` package suite without using `s3k`:

```
$ stack build --test --no-run-tests --bench --no-run-benchmarks --pedantic bar-api bar-client bar-core bar-server
```

That was quite a bit to type. Let's see if we can have `s3k` save us some
effort:

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
package suite: `barn`, `foo-bar`, `foo-bar-baz`, and `fubar. Let's work towards
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
on their own line, to a `grep -E` invocation, so we exploit this fact in our
regex.

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
or not test/bench targets exist in the first place. THat is why we don't see the
full package suite's packages on those lines.

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
$ s3k -b '^\<bar\>' -p -- --dry-run
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
distributed to each command in the final command list.

[`s3k` User Guide]: https://github.com/jship/s3k/blob/main/GUIDE.md
