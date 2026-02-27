using PetoiBittle
using Documenter

DocMeta.setdocmeta!(PetoiBittle, :DocTestSetup, :(using PetoiBittle); recursive = true)

makedocs(;
    modules = [PetoiBittle],
    authors = "Dmitry Bagaev <bvdmitri@gmail.com> and contributors",
    sitename = "PetoiBittle.jl",
    format = Documenter.HTML(;
        canonical = "https://bvdmitri.github.io/PetoiBittle.jl", edit_link = "main", assets = String[]
    ),
    pages = ["Home" => "index.md", "Commands" => "commands.md"]
)

deploydocs(; repo = "github.com/bvdmitri/PetoiBittle.jl", devbranch = "main")
