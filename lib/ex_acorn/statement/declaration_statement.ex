defmodule ExAcorn.Statement.DeclarationStatement do
  import NimbleParsec
  import ExAcorn.Utils

  def variable_statement(expression_combinator \\ empty()) do
    declaration =
      choice([
        ignore(eq())
        |> optional(whitespace())
        |> repeat(
          lookahead_not(ascii_char([?\n, ?\r, ?\,, ?\=, ?;]))
          |> concat(expression_combinator)
        )
        |> optional(
          comma()
          |> ignore()
          |> concat(whitespace())
          |> ignore()
        )
        |> tag(:init),
        ignore(comma())
        |> optional(whitespace())
        |> tag(:init)
      ])

    declaration_id =
      line_text()
      |> optional(space_chars())
      |> unwrap_and_tag(:id)

    declarations =
      repeat(
        lookahead_not(expression_boundary())
        |> concat(declaration_id)
        |> optional(space_chars())
        |> optional(declaration)
        |> tag(:variable_declarator)
      )
      |> post_traverse({:rollup_sequence, []})
      |> tag(:declarations)

    choice([string("let"), string("const"), string("var")])
    |> unwrap_and_tag(:kind)
    |> ignore(whitespace())
    |> concat(declarations)
    |> ignore(expression_boundary())
    |> tag(:variable_statement)
  end

  def rollup_sequence(_, args, context, _, _) do
    args = do_rollup_sequence(args)
    {args, context}
  end


  defp do_rollup_sequence(args) do
    Enum.flat_map(args, fn {k, props} = arg ->
      case Keyword.fetch!(props, :init) do
        [{:seq, [expressions: exprs]}]->
          [cur_init | expressions] = Enum.reverse(exprs)
          props =
            props
            |> Keyword.delete(:init)
            |> Keyword.put(:init, cur_init)
          [{k, props} | Enum.map(expressions, &to_declaration/1)]
        _ ->
          [arg]
      end
    end)
  end

  defp to_declaration({k, props}) do
    IO.inspect(k, label: "to_declaration({k, props})")
    {source_loc, rest} = Keyword.split(props, [:end_loc, :start_loc])

    declarator_props =
      {k, rest}
      |> do_to_declaration()
      |> Keyword.put_new(:init, [])
      |> Enum.concat(source_loc)

    {:variable_declarator, declarator_props}
  end

  defp do_to_declaration({:binary_expression, props} = init) do
    props
    |> Keyword.fetch!(:right)
    |> do_to_declaration()
    |> Keyword.put(:init, init)
  end

  defp do_to_declaration({:identifier, props}) do
    [id: Keyword.fetch!(props, :name)]
  end
end
