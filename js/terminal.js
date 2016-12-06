window.buffer = '';

function getBreakpoints(){
    breakpoints = window.editor.session.getBreakpoints(undefined, 0);
    breakpoints = Object.keys(breakpoints);
    breakpoints = breakpoints.map((e) => {return parseInt(e)+1;});
    return breakpoints;
}

jQuery(function($, undefined) {
  $('#terminal').terminal(function(command, term) {
      if (command !== '') {
          try {
              window.w.postMessage({ command: "continue", input: command, breakpoints: getBreakpoints() });
          } catch(e) {
              term.error(new String(e));
          }
      } else {
         term.echo('');
      }
  }, {
      greetings: '',
      name: 'cmm-terminal',
      height: 200,
      prompt: ''
  });
});
