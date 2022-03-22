# [`s3k` User Guide][]

This user guide provides a walkthrough of usage of `s3k`. It is intended to be
interactive, so if you'd like to run all the demonstrated commands throughout
this guide, you can generate the companion monorepo via:

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

[`s3k` User Guide]: https://github.com/jship/s3k/blob/main/GUIDE.md
