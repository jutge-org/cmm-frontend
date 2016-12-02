importScripts('index.min.js');

{ compile, execute, events, hooks } = self.cmm

events.onstdout ((output) -> setOutput output)

iterator = null

STATUS_MSGS = Object.freeze({
    WAITING_INPUT: "Waiting for input"
    PAUSED: "Paused"
    COMPILATION_ERROR: "Compilation error: "
    EXECUTION_ERROR: "Execution error: "
    RUNNING: "Running"
    EXIT_SUCCESS: "Program finished successfully"
})

COLOR = Object.freeze({
    YELLOW: "yellow"
    ORANGE: ""
    RED: "red"
    GREEN: "#90EE90"
    WHITE: "white"
})

makeCompilation = (code, showAst = no) ->
    setOutput ""
    setStatus "Compiling"

    try
        ast = compile code
    catch error
        console.log(error.stack ? error.message ? error)
        setOutput "#{error.message}"
        setStatus STATUS_MSGS.COMPILATION_ERROR, COLOR.RED
        return

    setOutput "#{JSON.stringify(ast, null, 4)}" if showAst
    setStatus "Compiled"
    ast


makeExecution = (ast, input) ->
    setStatus STATUS_MSGS.RUNNING

    try
        iterator = execute(ast, input)
        loop
            { value, done } = iterator.next()
            if inspectValue value
                setStatus STATUS_MSGS.WAITING_INPUT, COLOR.YELLOW
                return
            break unless not done
            result = value
        { stderr, status } = result
    catch error
        console.log(error.stack ? error.message ? error)
        setOutput "#{error.stack ? error.message}"
        return

    setStatus status, COLOR.GREEN

resumeExecution = ->
    try
        loop
            { value, done } = iterator.next()
            if inspectValue value
                setStatus STATUS_MSGS.WAITING_INPUT, COLOR.YELLOW
                return
            break unless not done
            result = value
        { stderr, status } = result
        status = STATUS_MSGS.EXIT_SUCCESS if status is 0
    catch error
        console.log(error.stack ? error.message ? error)
        setOutput "#{error.stack ? error.message}"
        return

    setStatus status, COLOR.GREEN

inspectValue = (value) ->
    return no if not value?
    return no if typeof value is 'number'
    return no if typeof value.getType isnt 'function'
    return no if not hooks.isInputBufferEmpty()
    value.getType() is 'CIN'

setOutput = (s) -> postMessage({ type: "output", value: s })
setStatus = (s, c) -> postMessage({ type: "status", value: {msg: s, color: c} })

onmessage = (e) ->
    { data: { command, code, input } } = e

    if command is "compile"
        makeCompilation(code, yes)
    else if command is "continue"
        if input?
            hooks.setInput input
        resumeExecution()
    else
        ast = makeCompilation(code)
        if ast?
            makeExecution(ast, input)
