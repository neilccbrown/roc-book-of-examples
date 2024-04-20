app "TestLZ77"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br" }
    imports [LZ77, pf.Stdout, pf.Stderr, pf.Arg, pf.File, pf.Path, pf.Task.{ await }]
    provides [main] to pf

main = Task.onErr (
  files <- await Arg.list
  when files is
    [_, file] ->
        content <- await (File.readUtf8 (Path.fromStr file))
        # For debugging:
        #{} <- await (Stdout.line (content |> Str.toUtf8 |> LZ77.encode |> Inspect.toStr))
        {} <- await (Stdout.line (Result.withDefault (content |> Str.toUtf8 |> LZ77.encode |> LZ77.decode |> Str.fromUtf8) ""))
        Task.ok {}
    _ ->
        {} <- await (Stderr.line "Pass a single file path" )
        Task.ok {} # It's not okay, but can't work out how to throw a custom error here and make the types match across when branches    
  ) (\_err ->
    # How do I convert err to string?  The toInspect ability?
    {} <- await (Stderr.line "Error of some type")
    Task.err -1
    )        