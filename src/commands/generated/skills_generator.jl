# Code generator for the built-in named skills declared in `skills_table.jl`.
#
# For every row it emits, at module-definition (precompile) time:
#   - a singleton `Command` subtype (with a docstring),
#   - its zero-allocation `serialize_to_bytes!` method (writes the fixed token),
#   - a convenience verb `verb(connection)` (with a docstring),
# and, after the loop, registers all generated names as public API.
#
# Generation runs while the module is being defined, so the methods are baked into the
# precompilation cache: there is no runtime `eval` and no world-age cost for callers.

"""
    skills_overview()

Return the metadata table of all built-in named skills (gaits, postures, behaviors) as a
tuple of named tuples with fields `category`, `julia_name`, `verb`, `token`, `description`.

Each row corresponds to a generated [`PetoiBittle.Command`](@ref) subtype (`julia_name`) and
a convenience verb (`verb`). This table powers the documentation overview as well as the
package's own tests.

```jldoctest
julia> row = first(filter(r -> r.julia_name === :Sit, PetoiBittle.skills_overview()));

julia> (row.verb, row.token)
(:sit, "ksit")
```
"""
skills_overview() = NAMED_SKILLS

for row in NAMED_SKILLS
    T = row.julia_name
    verb = row.verb
    token = row.token
    desc = row.description
    cat = row.category

    typedoc = """
        $T()

    A [`PetoiBittle.Command`](@ref) (category: **$cat**) that makes the robot $desc.

    Serializes to the firmware token `"$token"`. Send it explicitly with
    [`PetoiBittle.send_command`](@ref), or use the convenience verb
    [`PetoiBittle.$verb`](@ref).
    """

    verbdoc = """
        $verb(connection)

    Make the robot $desc (category: **$cat**).

    Convenience wrapper, equivalent to `send_command(connection, $T())`.
    """

    @eval begin
        @doc $typedoc struct $T <: Command end

        Base.@propagate_inbounds serialize_to_bytes!(bytes, ::$T, startidx::Int) =
            _serialize_token!(bytes, $token, startidx)

        @doc $verbdoc $verb(connection::Connection) = send_command(connection, $T())
    end
end

# Mark every generated name (and `skills_overview`) as public API. `public` is only available
# as a parser keyword on Julia 1.11+; on 1.10 the API is still reachable as `PetoiBittle.<name>`
# and the marking is simply a no-op, mirroring the `@compat public` declarations elsewhere.
@static if VERSION >= v"1.11"
    let names = Symbol[:skills_overview]
        for row in NAMED_SKILLS
            push!(names, row.julia_name, row.verb)
        end
        eval(Expr(:public, names...))
    end
end
