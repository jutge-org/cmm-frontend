window.buffer = '';

jQuery(function($, undefined) {
  $('#terminal').terminal(function(command, term) {
      if (command !== '') {
          try {
              window.w.postMessage({ command: "continue", input: command });
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
