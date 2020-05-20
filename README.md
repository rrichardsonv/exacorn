# ExAcorn

## Setup

```
mix deps.get
```

## Usage

Currently super broken, the whole thing needs to be switched over to use proper operator precedence parsing. To see the output run:

```
mix test test/statement_test.exs:212
```

If you want to jump back to when all the tests parsed everything EXCEPT operator precedence correctly

```
git checkout 0772080
```

and run:

```
mix test test/statement_test.exs
```
