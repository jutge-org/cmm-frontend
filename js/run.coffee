importScripts('index.min.js');

{ compile, execute, events } = self.cmm

events.onstdout (
        (output) -> setOutput output
    )

makeCompilation = (code, showAst = no) ->
    setOutput ""
    setStatus "Compiling"

    try
        ast = compile code
    catch error
        console.log(error.stack ? error.message ? error)
        setOutput "#{error.message}"
        setStatus "Compilation error"
        return

    setOutput "#{JSON.stringify(ast, null, 4)}" if showAst
    setStatus "Compiled"
    ast


makeExecution = (ast, input) ->
    setStatus "Running"

    try
        { stderr, status } = execute(ast, input)
    catch error
        console.log(error.stack ? error.message ? error)
        setOutput "#{error.stack ? error.message}"
        return

    setStatus status

setOutput = (s) -> postMessage({ type: "output", value: s })
setStatus = (s) -> postMessage({ type: "status", value: s })

onmessage = (e) ->
    { data: { command, code, input } } = e

    if command is "compile"
        makeCompilation(code, yes)
    else
        ast = makeCompilation(code)
        if ast?
            makeExecution(ast, input)
