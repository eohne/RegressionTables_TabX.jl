"""
    abstract type AbstractLatex <: AbstractRenderType end

The abstract type for most plain text rendering. Printing is defined using the `AbstractLatex`, so
new tables (with different defaults) can be created by subtyping `AbstractLatex` with minimal effort.
"""
abstract type AbstractLatex <: AbstractRenderType end

"""
    struct LatexTable <: AbstractLatex end

The main concrete type for [`AbstractLatex`](@ref). This type is
used to create Latex tables.
"""
struct LatexTable <: AbstractLatex end

"""
    struct LatexTableStar <: AbstractLatex end

An alternative concrete type for [`AbstractLatex`](@ref). This type is
used to create Latex tables that span the entire text width.
"""
struct LatexTableStar <: AbstractLatex end

function Base.repr(render::AbstractLatex, val::Pair; align="c", args...)
    s = repr(render, first(val); args...)
    # need to print the multicolumn version since it will miss & otherwise
    if length(s) == 0 && length(last(val)) == 1
        s
    else
        multicolumn(render, s, length(last(val)), align)
    end
end

function Base.print(io::IO, row::DataRow{T}) where T<:AbstractLatex
    render = T()
    print(io, linestart(render))
    for (i, x) in enumerate(row.data)
        print(
            io,
            make_padding(repr(render, x; align = row.align[i]), row.colwidths[i], row.align[i])
        )
        if i < length(row.data)
            print(io, colsep(render))
        end
    end
    print(io, lineend(render))
    if any(row.print_underlines)
        println(io)
        for (i, x) in enumerate(row.data)
            s = isa(x, Pair) ? repr(render, first(x)) : repr(render, x)
            if length(s) == 0 || !row.print_underlines[i]
                continue
            end
            if isa(x, Pair)
                print(io, underline(render, first(last(x)), last(last(x))))
            else
                print(io, underline(render, i,i))
            end
        end
    end
end


multicolumn(::AbstractLatex, s, cols::Int, align="c") = "\\multicolumn{$cols}{$align}{$s}"
tablestart(::AbstractLatex, align) = "\\begin{tabularx}{\\textwidth}{@{}l*{$(length(align)-1)}{Y}@{}}"
tableend(::AbstractLatex) = "\\end{tabularx}"
tablestart(::LatexTableStar, align) = "\\begin{tabularx*}{\\textwidth}{@{}l*{$(length(align)-1)}{Y}@{}}"
tableend(::LatexTableStar) = "\\end{tabularx*}"
underline(::AbstractLatex, colmin::Int, colmax::Int) = "\\cmidrule(lr){$(colmin)-$(colmax)} "

toprule(::AbstractLatex) = "\\midrule \\midrule"
midrule(::AbstractLatex) = "\\midrule"
bottomrule(::AbstractLatex) = "\\midrule \\midrule"
colsep(::AbstractLatex) = " & "
linestart(::AbstractLatex) = ""
lineend(::AbstractLatex) = " \\\\ "

# functions to make multiple dispatch easier
tablestart(tab::RegressionTable{<:AbstractLatex}) = tablestart(tab.render, tab.align)
underline(tab::RegressionTable{<:AbstractLatex}, colmin::Int, colmax::Int) = headerule(tab.render, colmin, colmax)




label(::AbstractLatex, x::Type{Nobs}) = "\$" * label(AsciiTable(), x) * "\$"
label(::AbstractLatex, x::Type{R2}) = "\$R^2\$"
label(::AbstractLatex, x::Type{FStat}) = "\$" * label(AsciiTable(), x) * "\$"
label_p(::AbstractLatex) = "\$" * label_p(AsciiTable()) * "\$"
#wrapper(::AbstractLatex, x) = #"\$^{$x}\$"
interaction_combine(::AbstractLatex) = " \$\\times\$ "