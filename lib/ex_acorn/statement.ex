defmodule ExAcorn.Statement do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common
  import ExAcorn.Statement.SwitchStatement
  import ExAcorn.Statement.BreakStatement
  import ExAcorn.Statement.ContinueStatement
  import ExAcorn.Statement.ThrowStatement
  import ExAcorn.Statement.ReturnStatement
  import ExAcorn.Statement.ExportStatement
  import ExAcorn.Statement.ImportStatement
  import ExAcorn.Statement.ClassStatement
  import ExAcorn.Statement.IfStatement
  import ExAcorn.Statement.WithStatement
  import ExAcorn.Statement.TryStatement
  import ExAcorn.Statement.DebuggerStatement
  import ExAcorn.Statement.WhileStatement
  import ExAcorn.Statement.LabelStatement
  import ExAcorn.Statement.ForStatement
  import ExAcorn.Statement.FunctionStatement
  import ExAcorn.Statement.BlockStatement

  import ExAcorn.Expression.Function

  defcombinatorp(
    :_statement,
    choice([
      optional(whitespace()) |> concat(break_statement()),
      optional(whitespace()) |> concat(class_statement(parsec(:_block))),
      optional(whitespace()) |> concat(continue_statement()),
      optional(whitespace()) |> concat(debugger_statement()),
      optional(whitespace()) |> concat(for_statement(parsec(:_block))),
      optional(whitespace()) |> concat(function_statement(parsec(:_block))),
      optional(whitespace()) |> concat(if_statement(parsec(:_block))),
      optional(whitespace()) |> concat(return_statement()),
      optional(whitespace()) |> concat(switch_statement()),
      optional(whitespace()) |> concat(throw_statement()),
      optional(whitespace()) |> concat(try_statement(parsec(:_block))),
      optional(whitespace()) |> concat(variable_statement()),
      optional(whitespace()) |> concat(while_statement(parsec(:_block))),
      optional(whitespace()) |> concat(do_statement(parsec(:_block))),
      optional(whitespace()) |> concat(with_statement(parsec(:_block))),
      optional(whitespace()) |> concat(block_statement(parsec(:_block))),
      optional(whitespace()) |> concat(label_statement())
    ])
  )

  defcombinatorp(
    :_quotes_and_comments,
    choice([
      optional(whitespace()) |> concat(comment()),
      optional(whitespace()) |> concat(quoted_string())
    ])
  )

  defcombinatorp(
    :_expression,
    optional(whitespace()) |> concat(function_expression())
  )

  defcombinatorp(
    :_fallback,
    choice([
      optional(whitespace()) |> concat(comma()),
      optional(whitespace()) |> concat(semi()),
      optional(whitespace()) |> concat(period()),
      optional(whitespace()) |> concat(open_paren()),
      optional(whitespace()) |> concat(close_paren()),
      optional(whitespace()) |> concat(colon()),
      optional(whitespace()) |> concat(eq()),
      optional(whitespace()) |> concat(question_mark()),
      whitespace(),
      optional(whitespace()) |> concat(non_control_char())
    ])
  )

  defcombinatorp(
    :_block,
    local_block(
      choice([
        parsec(:_quotes_and_comments),
        parsec(:_statement),
        parsec(:_expression)
      ])
    )
  )

  defcombinatorp(
    :statement,
    optional(whitespace())
    |> choice([
      if_statement(),
      break_statement(),
      continue_statement(),
      with_statement(),
      switch_statement(),
      return_statement(),
      throw_statement(),
      try_statement(),
      while_statement(),
      do_statement(),
      for_statement(),
      label_statement(),
      debugger_statement(),
      block_statement()
    ])
    |> label("statement")
  )

  root =
    choice([
      parsec(:_quotes_and_comments),
      export_statement(),
      import_meta_statement(),
      import_statement(),
      parsec(:_statement),
      parsec(:_expression),
      parsec(:_fallback),
      close_brace(),
      open_brace(),
      open_paren(),
      close_paren()
    ])

  defparsec(
    :parse,
    optional(whitespace())
    |> repeat(lookahead_not(eos()) |> concat(root))
    |> eos()
  )
end
