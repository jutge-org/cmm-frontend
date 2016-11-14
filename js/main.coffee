$ -> # Equivalent to $(document).ready(function() {...})
# Place the code editor
    editor = ace.edit("editor")
    editor.$blockScrolling = Infinity
    editor.setTheme("ace/theme/twilight")
    editor.getSession().setMode("ace/mode/c_cpp")
    editor.setValue(samplePrograms.default.code, -1)

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
        else
            e.editor.session.clearBreakpoint(row)
        e.stop()
    )

    w = null
    do resetWorker = ->
        w = new Worker("js/run.min.js")

        w.onmessage = (e) ->
            { data: { type, value }} = e
            if type is "status"
                $("#exitstatus").text(value)
            else
                $("#output").text(value)

    $("#compile").click(->
        w.postMessage({ command: "compile", code: editor.getValue() })
    )

    $("#run").click(->
        w.postMessage({ command: "run", code: editor.getValue(), input: $("#input").val() })
    )

    $("#kill").click(->
        $("#exitstatus").text("Killed")
        w.terminate()
        resetWorker()
    )

    $(".dropdown-menu li a").click(->
        option = $(this).text()
        data = $(this).data('value')
        $(this).parents(".dropdown").find('.btn').html(option + ' <span class="caret"></span>')
        editor.setValue(samplePrograms[data].code, -1)
        breakpoints = editor.session.getBreakpoints(undefined, 0)
        for b of breakpoints
            editor.session.clearBreakpoint(b);
        $("#input").val(samplePrograms[data].in)
    )

# Name the entries after the data-value attribute
samplePrograms =
    default:
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
