defmodule ExAcorn.Statement do
  import NimbleParsec
  import ExAcorn.Utils
  import ExAcorn.Common
  import ExAcorn.Operators
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
  import ExAcorn.Statement.DeclarationStatement
  import ExAcorn.Statement.EmptyStatement

  import ExAcorn.Expression.Function
  import ExAcorn.Expression.Array
  import ExAcorn.Expression.Member
  import ExAcorn.Expression.Object
  import ExAcorn.Expression.New

  defcombinatorp(
    :_statement,
    choice([
      optional(whitespace()) |> concat(break_statement()),
      optional(whitespace()) |> concat(class_statement(parsec(:_block))),
      optional(whitespace()) |> concat(continue_statement()),
      optional(whitespace()) |> concat(debugger_statement()),
      optional(whitespace()) |> concat(for_statement(parsec(:_expression), parsec(:_block))),
      optional(whitespace()) |> concat(function_statement(parsec(:_block))),
      optional(whitespace()) |> concat(if_statement(parsec(:_expression), parsec(:_block))),
      optional(whitespace()) |> concat(return_statement()),
      optional(whitespace()) |> concat(switch_statement(parsec(:_expression), parsec(:_base))),
      optional(whitespace()) |> concat(variable_statement(parsec(:_expression))),
      optional(whitespace()) |> concat(throw_statement()),
      optional(whitespace()) |> concat(try_statement(parsec(:_block))),
      optional(whitespace()) |> concat(while_statement(parsec(:_expression), parsec(:_block))),
      optional(whitespace()) |> concat(do_statement(parsec(:_expression), parsec(:_block))),
      optional(whitespace()) |> concat(with_statement(parsec(:_expression), parsec(:_block))),
      optional(whitespace()) |> concat(block_statement(parsec(:_block))),
      optional(whitespace()) |> concat(label_statement()),
      optional(whitespace()) |> concat(empty_statement())
    ])
  )

  defcombinatorp(
    :_literal,
    choice([
      optional(whitespace()) |> concat(regular_expression()),
      optional(whitespace()) |> concat(comment()),
      optional(whitespace()) |> concat(quoted_string()),
      optional(whitespace()) |> concat(bool_or_null_literal()),
      optional(whitespace()) |> concat(integer()) |> unwrap_and_tag(:integer),
      optional(whitespace()) |> concat(float()) |> unwrap_and_tag(:float)
    ])
    |> tag(:literal)
  )

  defcombinatorp(
    :_expression,
    choice([
      parsec(:_literal),
      optional(whitespace()) |> concat(operator()),
      optional(whitespace()) |> concat(function_expression(parsec(:_block))),
      optional(whitespace()) |> concat(object_expression(parsec(:_literal))),
      optional(whitespace()) |> concat(new_expression(parsec(:_expression))),
      optional(whitespace())
      |> concat(member_expression(parsec(:_expression))),
      optional(whitespace())
      |> concat(
        array_expression([
          parsec(:_literal),
          parsec(:_expression)
        ])
      ),
      optional(whitespace()) |> concat(line_text() |> tag(:name) |> tag(:identifier))
    ])
    |> optional(parsec(:_paramaterized))
    |> post_traverse({:scoop_up_in, []})
  )

  defp scoop_up_in(
         _rest,
         [{:call_expression, call_bod}, {:orphaned_member_expression, _} = callee_expr],
         context,
         _line,
         _offset
       ) do
    {[{:orphaned_member_call_expression, [{:callee, callee_expr} | call_bod]}], context}
  end

  defp scoop_up_in(_rest, [{:call_expression, call_bod}, callee_expr], context, _line, _offset) do
    {[{:call_expression, [{:callee, callee_expr} | call_bod]}], context}
  end

  defp scoop_up_in(_, args, context, _, _), do: {args, context}

  defcombinatorp(
    :_paramaterized,
    optional(whitespace())
    |> concat(
      paren_group([parsec(:_expression)])
      |> tag(:arguments)
    )
    |> tag(:call_expression)
  )

  defcombinatorp(
    :_fallback,
    choice([
      optional(whitespace()) |> concat(comma()),
      optional(whitespace()) |> concat(semi()),
      optional(whitespace()) |> concat(period()),
      optional(whitespace()) |> concat(open_paren()),
      optional(whitespace()) |> concat(close_paren()),
      optional(whitespace()) |> concat(open_bracket()),
      optional(whitespace()) |> concat(close_bracket()),
      optional(whitespace()) |> concat(colon()),
      optional(whitespace()) |> concat(eq()),
      optional(whitespace()) |> concat(question_mark()),
      whitespace(),
      optional(whitespace()) |> concat(non_control_char())
    ])
  )

  defcombinatorp(
    :_base,
    choice([
      parsec(:_literal),
      parsec(:_statement),
      parsec(:_expression)
    ])
  )

  defcombinatorp(
    :_block,
    curly_group([
      parsec(:_literal),
      parsec(:_statement),
      parsec(:_expression)
    ])
  )

  root =
    choice([
      parsec(:_literal),
      export_statement([
        class_statement(parsec(:_block)),
        function_statement(parsec(:_block)),
        variable_statement(parsec(:_expression))
      ]),
      import_meta_statement(),
      import_statement(),
      parsec(:_statement),
      parsec(:_expression),
      parsec(:_fallback),
      close_brace(),
      open_brace(),
      open_paren(),
      close_paren(),
      open_bracket(),
      close_bracket()
    ])

  defparsec(
    :parse,
    optional(whitespace())
    |> repeat(lookahead_not(eos()) |> concat(root))
    |> eos()
  )
end
