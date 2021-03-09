function startProcessingClicked() {
  let inputArea = document.getElementById('input-textarea');
  let outputArea = document.getElementById('output-textarea');

  outputArea.value = '';
  initServerCommunication(inputArea.value);
}

function initServerCommunication(data) {
  let socket = new WebSocket("ws://localhost:3000/ws");

  socket.onopen = () => socket.send(data);
  socket.onmessage = (event) => processServerEvent(socket, event);

  socket.onclose = (event) => {
    if (event.wasClean) {
      console.log('closed clean')
    } else {
      console.log('closed killed')
    }
  };

  socket.onerror = function(error) {
    console.log(error)
  };
}

function processServerEvent(socket, event) {
  console.log("Server event: ", event.data);

  // TODO: handle case when | is part of the URL
  let [cmd, text] = (event.data || "").split(" > ");

  switch(cmd.trim().toLowerCase()) {
    case 'error':
      handleServerError(socket, text);
      break;
    case 'start':
      handleServerStart();
      break;
    case 'finish':
      handleServerFinish(socket, text);
      break;
    case 'process':
      handleItemProcessed(text);
      break;
    default:
      console.error(`invalid command: '${cmd}'`);
  }
}

function handleServerError(socket, text) {
  console.error(text);
  socket.close();
}

function handleServerStart() {
  let startButton = document.getElementById('start-button');
  startButton.setAttribute('disabled', true);
}

function handleServerFinish(socket, text) {
  socket.close();

  let startButton = document.getElementById('start-button');
  startButton.removeAttribute('disabled');

  // TODO: set total execution time
}

function handleItemProcessed(text) {
  document.getElementById('output-textarea').value += `${text}\n\n`;
}
