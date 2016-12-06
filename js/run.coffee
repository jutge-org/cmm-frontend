importScripts('index.min.js');

{ compile, execute, events, hooks } = self.cmm

events.onstdout ((output) -> setOutput output)

iterator = null
brkpnts = null

STATUS_MSGS = Object.freeze({
    WAITING_INPUT: "Waiting for input"
    PAUSED: "Paused"
    COMPILATION_ERROR: "Compilation error"
    EXECUTION_ERROR: "Execution error"
    RUNNING: "Running"
    EXIT_SUCCESS: "Program finished successfully"
})

COLOR = Object.freeze({
    YELLOW: "yellow"
    ORANGE: "orange"
    RED: "red"
    GREEN: "#90EE90"
    WHITE: "white"
})

makeCompilation = (code, showAst = no) ->
    setStatus "Compiling"

    try
        ast = compile code
    catch error
        console.log(error.stack ? error.message ? error)
        setErrorMsg "#{error.stack ? error.message ? error}"
        setStatus STATUS_MSGS.COMPILATION_ERROR, COLOR.RED
        return

    setOutput "#{JSON.stringify(ast, null, 4)}" if showAst
    setStatus "Compiled"
    ast


makeExecution = (ast, input) ->
    setStatus STATUS_MSGS.RUNNING
    statusColor = COLOR.GREEN
    try
        iterator = execute(ast, input)
        loop
            { value, done } = iterator.next()
            if isCIN value
                setStatus STATUS_MSGS.WAITING_INPUT, COLOR.YELLOW
                return
            if hasBreakpoint value
                setStatus STATUS_MSGS.PAUSED, COLOR.ORANGE
                return
            break unless not done
            result = value
        { stderr, status } = result
        status = STATUS_MSGS.EXIT_SUCCESS if status is 0
    catch error
        console.log(error.stack ? error.message ? error)
        setErrorMsg "#{error.stack ? error.message}"
        status = STATUS_MSGS.EXECUTION_ERROR
        statusColor = COLOR.RED

    iterator = null
    brkpnts = null
    setStatus status, statusColor
    killVM()

resumeExecution = ->
    setStatus STATUS_MSGS.RUNNING
    statusColor = COLOR.GREEN
    try
        loop
            { value, done } = iterator.next()
            if isCIN value
                setStatus STATUS_MSGS.WAITING_INPUT, COLOR.YELLOW
                return
            if hasBreakpoint value
                setStatus STATUS_MSGS.PAUSED, COLOR.ORANGE
                return
            break unless not done
            result = value
        { stderr, status } = result
        status = STATUS_MSGS.EXIT_SUCCESS if status is 0
    catch error
        console.log(error.stack ? error.message ? error)
        setErrorMsg "#{error.stack ? error.message ? error}"
        status = STATUS_MSGS.EXECUTION_ERROR
        statusColor = COLOR.RED

    iterator = null
    brkpnts = null
    setStatus status, statusColor
    killVM()

isCIN = (value) ->
    return no if not value?
    return no if typeof value is 'number'
    return no if typeof value.getType isnt 'function'
    return no if not hooks.isInputBufferEmpty()
    value.getType() is 'CIN'

hasBreakpoint = (value) ->
    return no if not value?
    value.instrNumber in brkpnts

setOutput = (s) -> postMessage({ type: "output", value: s })
setErrorMsg = (s) -> postMessage({ type: "errormsg", value: s })
setStatus = (s, c=COLOR.WHITE) -> postMessage({ type: "status", value: {msg: s, color: c} })
killVM = -> postMessage({ type: "terminate" })

onmessage = (e) ->
    { data: { command, code, input, breakpoints } } = e

    if command is "compile"
        makeCompilation(code, yes)
    else if command is "continue"
        brkpnts = breakpoints
        if input?
            hooks.setInput input
        if iterator isnt null
            resumeExecution()
    else
        brkpnts = breakpoints
        ast = makeCompilation(code)
        if ast?
            makeExecution(ast, input)
