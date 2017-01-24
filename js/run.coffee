importScripts('index.min.js');

{ compile, execute, events: { onstdout }, hooks: { setInput, isInputBufferEmpty, modifyVariable }, actions: { stepOut, stepOver, stepInto } } = self.cmm

onstdout((output) -> setOutput output)

iterator = null
brkpnts = null
waitingForInput = no
pauseFlag = no

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
        killVM()
        return

    setOutput "#{JSON.stringify(ast, null, 4)}" if showAst
    setStatus "Compiled"
    ast


runProgram = (ast , input, begin = no) ->
    setStatus STATUS_MSGS.RUNNING
    statusColor = COLOR.GREEN
    try
        iterator = execute(ast, input) if begin
        loop
            { value, done } = iterator.next()
            break unless not done
            result = value if value isnt 0
            { value, stack } = value
            if isCIN value
                waitingForInput = yes
                setStatus STATUS_MSGS.WAITING_INPUT, COLOR.YELLOW
                return
            else if value?.stop
                setStatus STATUS_MSGS.PAUSED, COLOR.ORANGE
                delete value.stop
                sendStackState stack
                highlightLine value.instrNumber
                return
            else if hasBreakpoint value or pauseFlag
                setStatus STATUS_MSGS.PAUSED, COLOR.ORANGE
                sendStackState stack
                highlightLine value.instrNumber
                pauseFlag = no
                return
        { value: { stderr, status } } = result
        status = STATUS_MSGS.EXIT_SUCCESS if status is 0
    catch error
        console.log(error.stack ? error.message ? error)
        setErrorMsg "#{error.stack ? error.message? error}"
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
    return no if not isInputBufferEmpty()
    value.getType() is 'CIN'

hasBreakpoint = (value) ->
    return no if not value?
    value.instrNumber in brkpnts

setOutput = (s) -> postMessage({ type: "output", value: s })
setErrorMsg = (s) -> postMessage({ type: "errormsg", value: s })
setStatus = (s, c=COLOR.WHITE) -> postMessage({ type: "status", value: {msg: s, color: c} })
sendStackState = (stack) -> postMessage({ type: "stack", value: stack })
highlightLine = (line) -> postMessage({ type: "line", value: line })
killVM = -> postMessage({ type: "terminate" })

onmessage = (e) ->
    { data: { command, code, input, breakpoints, varData, stackNumber } } = e

    switch command
      when "compile"
        makeCompilation(code, yes)
      when "continue"
        return if waitingForInput
        brkpnts = breakpoints
        if iterator isnt null
            runProgram()
      when "debug"
        brkpnts = breakpoints
        ast = makeCompilation(code)
        if ast?
            runProgram(ast, input, begin=yes)
      when "pause"
          pauseFlag = yes
      when "step-out"
        stepOut()
      when "step-over"
        stepOver()
      when "step-into"
        stepInto()
      when "var-change"
        modifyVariable(stackNumber, varData.name, varData.value)
      when "input"
        setInput input
        waitingForInput = no
        if iterator isnt null
            runProgram()
      when "run"
        brkpnts = {}
        ast = makeCompilation(code)
        if ast?
            runProgram(ast, input, begin=yes)
