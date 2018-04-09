[
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    transport: 2
  ],
  import_deps: [:phoenix, :ecto]
]
