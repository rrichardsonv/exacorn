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
  import ExAcorn.Expression.Call
  import ExAcorn.Expression.Conditional
  import ExAcorn.Expression.Unary
  import ExAcorn.Expression.Binary

  defcombinatorp(
    :_statement,
    choice([
      break_statement(),
      class_statement(parsec(:_block)),
      continue_statement(),
      debugger_statement(),
      for_statement(parsec(:expression), parsec(:_block)),
      function_statement(parsec(:pattern), parsec(:_block)),
      if_statement(parsec(:expression), parsec(:_base)),
      return_statement([
        parsec(:literal),
        parsec(:expression)
      ]),
      switch_statement(parsec(:expression), parsec(:_base)),
      variable_statement(parsec(:expression)),
      throw_statement(parsec(:expression)),
      try_statement(parsec(:_block)),
      while_statement(parsec(:expression), parsec(:_block)),
      do_statement(parsec(:expression), parsec(:_block)),
      with_statement(parsec(:expression), parsec(:_block)),
      block_statement(parsec(:_block)),
      label_statement(optional(comment()) |> optional(whitespace()) |> concat(parsec(:statement))),
      empty_statement()
    ])
    |> pre_traverse({ExAcorn.Conflict, :start_length, []})
    |> post_traverse({ExAcorn.Conflict, :end_length, []})
  )

  defcombinatorp(:statement, optional(whitespace()) |> concat(parsec(:_statement)))

  defcombinatorp(:_pattern, line_text() |> unwrap_and_tag(:name) |> tag(:identifier))
  defcombinatorp(:pattern, optional(whitespace()) |> concat(parsec(:_pattern)))

  defcombinatorp(
    :_literal,
    choice([
      regular_expression(),
      quoted_string(),
      bool_or_null_literal(),
      integer() |> unwrap_and_tag(:integer),
      float() |> unwrap_and_tag(:float)
    ])
    |> tag(:literal)
    |> pre_traverse({ExAcorn.Conflict, :start_length, []})
    |> post_traverse({ExAcorn.Conflict, :end_length, []})
  )

  defcombinatorp(:literal,
    optional(whitespace())
    |> choice([
      comment()
      |> pre_traverse({ExAcorn.Conflict, :start_length, []})
      |> post_traverse({ExAcorn.Conflict, :end_length, []}),
      parsec(:_literal)
    ])
  )

  defcombinatorp(
    :_expression,
    choice([
      unary_expression(parsec(:expression)),
      parsec(:literal),
      function_expression(parsec(:expression), parsec(:_block)),
      operator(),
      object_expression(parsec(:literal)),
      new_expression(parsec(:expression)),
      member_expression(parsec(:expression)),
      array_expression([
        parsec(:literal),
        parsec(:expression)
      ]),
      parsec(:pattern)
    ])
    |> pre_traverse({ExAcorn.Conflict, :start_length, []})
    |> post_traverse({ExAcorn.Conflict, :end_length, []})
    |> optional(
      call_expression(parsec(:expression))
      |> pre_traverse({ExAcorn.Conflict, :start_length, []})
      |> post_traverse({ExAcorn.Conflict, :end_length, []})
    )
    |> post_traverse({:scoop_up_in, []})
    |> choice([
        dangling_binary(parsec(:expression))
        |> pre_traverse({ExAcorn.Conflict, :start_length, []})
        |> post_traverse({ExAcorn.Conflict, :end_length, []}),
        dangling_conditional(parsec(:expression))
        |> pre_traverse({ExAcorn.Conflict, :start_length, []})
        |> post_traverse({ExAcorn.Conflict, :end_length, []}),
        empty()
    ])
    |> post_traverse({:fix_dat_dangle, []})
  )

  defcombinatorp(:expression, optional(whitespace()) |> concat(parsec(:_expression)))

  defp scoop_up_in(
         _rest,
         [{:call_expression, call_bod} | [{:orphaned_member_expression, _} = callee_expr | rest]],
         context,
         _line,
         _offset
       ) do
    {[{:orphaned_member_call_expression, [callee_expr | call_bod]} | rest], context}
  end

  defp scoop_up_in(_rest, [{:call_expression, call_bod} | [prev | rest]], context, _, _) do
    {[{:call_expression, [{:callee, prev} | call_bod]} | rest], context}
  end

  defp scoop_up_in(_, args, context, _, _), do: {args, context}


  defp fix_dat_dangle(_, [{:dangling_conditional, conditional} | [prev | rest]], context, _, _) do
    {[{:conditional_expression, [{:test, prev} | conditional]} | rest], context}
  end

  defp fix_dat_dangle(_, [{:dangling_binary, conditional} | [prev | rest]], context, _, _) do
    {[{:binary_expression, [{:left, prev} | conditional]} | rest], context}
  end

  defp fix_dat_dangle(_, args, context, _, _), do: {args, context}

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
      parsec(:literal),
      parsec(:statement),
      parsec(:expression)
    ])
  )

  defcombinatorp(
    :_block,
    curly_group([
      parsec(:literal),
      parsec(:statement),
      parsec(:expression)
    ])
  )

  root =
    choice([
      parsec(:literal),
      export_statement([
        class_statement(parsec(:_block)),
        function_statement(parsec(:_block)),
        variable_statement(parsec(:expression))
      ]),
      import_meta_statement(),
      import_statement(),
      parsec(:statement),
      parsec(:expression),
      parsec(:_fallback)
    ])

  defparsec(
    :parse,
    optional(whitespace())
    |> repeat(
      lookahead_not(eos())
      |> concat(root)
    )
    |> eos()
  )
end
