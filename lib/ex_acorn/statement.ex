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
      for_statement(parsec(:expressable), parsec(:_block)),
      function_statement(parsec(:pattern), parsec(:_block)),
      if_statement(parsec(:expressable), parsec(:_base)),
      return_statement([
        parsec(:literal),
        parsec(:expressable)
      ]),
      switch_statement(parsec(:expressable), parsec(:_base)),
      variable_statement(parsec(:expressable)),
      throw_statement(parsec(:expressable)),
      try_statement(parsec(:_block)),
      while_statement(parsec(:expressable), parsec(:_block)),
      do_statement(parsec(:expressable), parsec(:_block)),
      with_statement(parsec(:expressable), parsec(:_block)),
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
      function_expression(parsec(:expression), parsec(:_block)),
      operator(),
      object_expression(parsec(:literal)),
      new_expression(parsec(:expression)),
      member_expression(parsec(:expression)),
      array_expression([parsec(:expressable)]),
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
  )

  defcombinatorp(:expression, optional(whitespace()) |> concat(parsec(:_expression)))
  defcombinatorp(:expressable,
    repeat_while(
      choice([
        parsec(:expression),
        parsec(:literal),
        operator()
      ])
      |> post_traverse({:notch_status, []}),
      {__MODULE__, :check_notch, []}
    )
    |> post_traverse({__MODULE__, :resolve_precedence_tree, []})
  )

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
      parsec(:expressable)
    ])
  )

  defcombinatorp(
    :_block,
    curly_group([
      parsec(:literal),
      parsec(:statement),
      parsec(:expressable)
    ])
  )

  root =
    choice([
      parsec(:literal),
      export_statement([
        class_statement(parsec(:_block)),
        function_statement(parsec(:_block)),
        variable_statement(parsec(:expressable))
      ]),
      import_meta_statement(),
      import_statement(),
      parsec(:statement),
      parsec(:expressable),
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

  def resolve_precedence_tree(_, args, _context, _, _) do
    {ExAcorn.ShuntOnEm.parse(args), %{}}
  end


  def notch_status(<<?;, _::binary>>, [{token, _}] = args, _context, _, _) when token != :opp,
        do: {args, %{last_notch?: true}}
  def notch_status(<<?\n, _::binary>>, [{token, _}] = args, _context, _, _) when token != :opp,
    do: {args, %{last_notch?: true}}

  def notch_status(_, args, context, _, _), do: {args, context}

  def check_notch(_args, context, _, _) do
    if Map.get(context, :last_notch?) do
      {:halt, context}
    else
      {:cont, context}
    end
  end
end
