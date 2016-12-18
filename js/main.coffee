window.w = null

$ -> # Equivalent to $(document).ready(function() {...})

    mostRecentStackNumber = 0 # current stack number
    markedLines = {} # current breakpointed lines in the editor in the form of {lineNumber: markerObject}
    currentLine = 0 # current line of the program execution

# Place the code editor
    editor = ace.edit("editor")
    window.editor = editor
    editor.$blockScrolling = Infinity
    editor.setTheme("ace/theme/twilight")
    editor.getSession().setMode("ace/mode/c_cpp")
    editor.setValue(samplePrograms.default_template.code, -1)
    aceRange = ace.require('ace/range').Range;

    editor.on("guttermousedown", (e) ->
        target = e.domEvent.target
        if target.className.indexOf("ace_gutter-cell") == -1
            return
        if !editor.isFocused()
            editor.focus()
        if e.clientX > 25 + target.getBoundingClientRect().left
            return

        row = e.getDocumentPosition().row
        breakpoints = e.editor.session.getBreakpoints(row, 0)
        if typeof breakpoints[row] == typeof undefined
            e.editor.session.setBreakpoint(row)
            range = new aceRange(row, 0, row, 1);
            markedLines[row] = e.editor.session.addMarker(range, "warning", "fullLine", true);
        else
            e.editor.session.clearBreakpoint(row)
            editor.getSession().removeMarker markedLines[row]
            delete markedLines[row]
        e.stop()
    )

    # Enable datagrid variables

    onBeforeCellEdit = (index, field) -> return true
    onAfterEdit = (index, row, changes) ->
      row.value = parseInt(row.value) if row.type is "INT"
      window.w.postMessage({ command: "var-change", varData: row, stackNumber: mostRecentStackNumber })

    $('#jtg-cpp-variables-table')
      .datagrid({
          fit: true,
          fitColumns: true,
          singleSelect: true,
          border: false,
          columns: [[
            {
              field: 'name',
              title: 'Name'
            },
            {
              field: 'type',
              title: 'Type',
            },
            {
              field: 'value',
              title: 'Value',
              width: 10
              editor: 'text'
            }
          ]]
        })
        .datagrid('enableCellEditing')
        .datagrid({
          onBeforeCellEdit: onBeforeCellEdit,
          onAfterEdit: onAfterEdit
        });

    $('#jtg-cpp-frames-table')
        .datagrid({
          fit: true,
          fitColumns: true,
          singleSelect: true,
          border: false,
          columns: [[
            {
              field: 'level',
              title: 'Level'
            },
            {
              field: 'function',
              title: 'Level',
              width: 10
            }
          ]]
        });

    do resetWorker = ->
        window.w = new Worker("js/run.min.js")

        window.w.onmessage = (e) ->
            { data: { type, value }} = e
            if type is "status"
                {msg: s, color: c} = value
                $("#exitstatus").css("background-color", c)
                $("#exitstatus").text(s)
            else if type is "output"
                term = $.terminal.active()
                if value != '\n'
                    window.buffer += value
                else
                    term.echo window.buffer
                    window.buffer = ''
            else if type is "errormsg"
                term = $.terminal.active()
                term.echo "[[b;white;black]#{value}]"
            else if type is "stack"
                mostRecentStackNumber = value.length-1
                variables = value[mostRecentStackNumber].variables
                variablesData = {"rows":({"name":i,"type":variables[i].type,"value":variables[i].value} for i of variables)}
                $('#jtg-cpp-variables-table').datagrid({ data: variablesData })
                levelsData = {"rows":("level":i,"function":"#{s.funcName}(#{(s.variables[arg].value for arg in s.args).join(',')})" for s, i in value)}
                $('#jtg-cpp-frames-table').datagrid({ data: levelsData })
            else if type is "line"
                row = value - 1
                currentLine = row
                editor.getSession().removeMarker markedLines[row]
                range = new aceRange(row, 0, row, 1);
                markedLines[row] = editor.session.addMarker(range, "current-line", "fullLine", true);
            else #terminate
                editor.setReadOnly no
                resetWorker()


    $("#compile").click(->
        window.w.postMessage({ command: "compile", code: editor.getValue() })
    )

    $("#run-button,#run-menu").click(->
        editor.setReadOnly yes
        $.terminal.active().focus()
        window.w.postMessage({ command: "run", code: editor.getValue(), input: buffer })
    )

    $("#debug-button,#debug-menu").click(->
        editor.setReadOnly yes
        $.terminal.active().focus()
        window.w.postMessage({ command: "debug", code: editor.getValue(), input: buffer, breakpoints: getBreakpoints() })
    )

    $("#kill-button,#kill-menu").click(->
        editor.setReadOnly no
        $("#exitstatus").text("Killed")
        window.w.terminate()
        resetWorker()
    )

    $("#continue-button").click(->
        $.terminal.active().focus()
        editor.getSession().removeMarker markedLines[currentLine]
        range = new aceRange(currentLine, 0, currentLine, 1);
        markedLines[currentLine] = editor.session.addMarker(range, "warning", "fullLine", true);
        window.w.postMessage({ command: "continue", breakpoints: getBreakpoints() })
    )

    $("#pause-button").click(->
        window.w.postMessage({ command: "pause" })
    )

    $("#step-out-button").click(->
        window.w.postMessage({ command: "step-out" })
        window.w.postMessage({ command: "continue", breakpoints: getBreakpoints() })
    )

    $("#step-over-button").click(->
        window.w.postMessage({ command: "step-over" })
        window.w.postMessage({ command: "continue", breakpoints: getBreakpoints() })
    )

    $("#step-into-button").click(->
        window.w.postMessage({ command: "step-into" })
        window.w.postMessage({ command: "continue", breakpoints: getBreakpoints() })
    )

    $("#example-menu > div").click(->
        data = $(this).data('value')
        editor.setValue(samplePrograms[data].code, -1)
        breakpoints = editor.session.getBreakpoints(undefined, 0)
        for b of breakpoints
            editor.session.clearBreakpoint(b);
        for row of markedLines
            editor.getSession().removeMarker markedLines[row]
        markedLines = {}
    )

    getBreakpoints = ->
        breakpoints = editor.session.getBreakpoints(undefined, 0)
        breakpoints = Object.keys(breakpoints)
        breakpoints = breakpoints.map((e) -> parseInt(e)+1)
        breakpoints

# Name the entries after the data-value attribute
samplePrograms =
    default_template:
        code:
            """
                #include <iostream>
                using namespace std;

                int main() {

                }
            """
        in:
            ""
    bars:
        code:
            """
                #include <iostream>
                using namespace std;

                void escriu_estrella(int n) {
                    if (n == 0) cout << endl;
                    else {
                        cout << '*';
                        escriu_estrella(n - 1);
                    }
                }

                void escriu_barres(int n) {
                    if (n == 1) cout << '*' << endl;
                    else {
                        escriu_estrella(n);
                        escriu_barres(n - 1);
                        escriu_barres(n - 1);
                    }
                }

                int main() {
                    int n;
                    cin >> n;
                    escriu_barres(n);
                }
            """
        in:
            "4"
    hanoi:
        code:
            """
                #include <iostream>
                using namespace std;

                void hanoi(int n, char from, char to, char aux) {
                    if (n > 0) {
                        hanoi(n - 1, from, aux, to);
                        cout << from << " => " << to << endl;
                        hanoi(n - 1, aux, to, from);
                    }
                }

                int main() {
                    int ndiscos;
                    cin >> ndiscos;
                    hanoi(ndiscos, 'A', 'C', 'B');
                }
            """
        in:
            "8"
    rombes:
        code:
            """
                #include <iostream>
                using namespace std;

                int main() {
                    int x;
                    cin >> x;
                    for (int i = 1; i <= x; ++i) {
                        for (int j = 0; j < x + i - 1; ++j) {
                            if (j < x - i) cout << ' ';
                            else cout << '*';
                        }
                        cout << endl;
                    }
                    for (int i = 1; i < x; ++i) {
                        for (int j = 0; j < 2*x - i - 1; ++j) {
                            if (j >= i) cout << '*';
                            else cout << ' ';
                        }
                        cout << endl;
                    }
                }
            """
        in:
            "9"
    escacs:
        code:
            """
                #include <iostream>
                using namespace std;

                int main() {
                    int n;
                    cin >> n;
                    int suma = 0;
                    for (int i = 0; i < n; ++i) {
                        for (int j = 0; j < n; ++j) {
                            char a;
                            cin >> a;
                            if (j == i or j == n - i - 1) suma += a - '0';
                        }
                    }
                    cout << suma << endl;
                }
            """
        in:
            "3 975 123 450"
    gcd:
        code:
            """
                // P67723_en: Greatest common divisor
                // Pre: two strictly positive natural numbers a and b
                // Post: the greatest common divisor of a and b

                #include<iostream>

                using namespace std;

                int main() {
                    int a, b;
                    cin >> a >> b;
                    int a0 = a;     //we need to keep the value of the original a and b
                    int b0 = b;

                    while ( b != 0) {
                        int r = a%b;  //remainder
                        a = b;
                        b = r;
                    }
                    cout << "The gcd of " << a0 << " and " << b0 << " is " << a << "." << endl;
                }
            """
        in:
            "16104 3216"
