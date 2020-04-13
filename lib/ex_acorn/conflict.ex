defmodule ExAcorn.Conflict do
  def noop(_, a, c, _, _), do: {a, c}

  def base(_, a, c, _, _) when is_list(a) do
    case Enum.reduce(a, {:normal, []}, &resolve_orphans/2) do
      {:normal, acc} ->
        {Enum.reverse(acc), c}

      {leftover, acc} ->
        {Enum.reverse([leftover | acc]), c}
    end
  end

  def base(_, args, context, _, _), do: {args, context}

  def resolve_orphans({:orphaned_member_expression, _} = orphaned_expr, {:normal, acc}) do
    {orphaned_expr, acc}
  end

  def resolve_orphans(parent_expr, {{:orphaned_member_expression, child_expr}, acc}) do
    {:normal, [{:member_expression, [{:object, parent_expr} | child_expr]} | acc]}
  end

  def resolve_orphans(a, {:normal, acc}), do: {:normal, [a | acc]}

  def split_on_sequence(_, a, c, _, _), do: {a, c}
end
