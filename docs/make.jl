using DAQCore
using Documenter

DocMeta.setdocmeta!(DAQCore, :DocTestSetup, :(using DAQCore); recursive=true)

makedocs(;
    modules=[DAQCore],
    authors="Paulo Jabardo <pjabardo@ipt.br> and contributors",
    repo="https://github.com/pjsjipt/DAQCore.jl/blob/{commit}{path}#{line}",
    sitename="DAQCore.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
