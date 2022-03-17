# [`s3k`][]

## Synopsis

`s3k` sits between the Haskell developer and `stack`, aiming to improve
productivity when working in monorepos. The two main features are:

1. Specifying packages/targets for building/testing/GHCi/etc via extended
   regular expressions
1. Aliasing invocations

## Crash Course

Build packages with names containing `foo`:

```
$ s3k -b foo
```

Print invocation to build packages with names containing `foo`:

```
$ s3k -b foo -p
```

Test packages containing the whole word `foo`:

```
# s3k -t '\<foo\>'
```

Run GHCi with lib targets from packages with `foo` or `bar` prefixes:

```
# s3k -g '^(foo|bar).*:lib'
```

Alias running GHCi with lib targets from packages with `foo` or `bar` prefixes:

```
# s3k -g '^(foo|bar).*:lib*' -s ghci-foo-bar -p
```

Run GHCi via the alias created in the previous example:

```
# s3k -a ghci-foo-bar
```

Run ghcid using the previous example's alias as input:

```
# ghcid --command "$(s3k -a ghci-foo-bar -p)"
```

Save the previous command to an alias:

```
# s3k -x 'ghcid --command "$(s3k -a ghci-foo-bar -p)"' -s ghcid-foo-bar -p
```

Run ghcid via the alias created in the previous example:

```
# s3k -a ghcid-foo-bar
```

## Installation

STUB

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
interact with some slice of a monorepo though, and `s3k would be inhumane if it
expected them to do so. For this reason, 's3k' heavily encourages aliasing
commands. The developer can type in their desired regex, save it away in an
alias, and then never think about the regex again.

[`s3k`]: https://github.com/jship/s3k
