function startProcessingClicked() {
  let inputArea = document.getElementById('input-textarea');
  let outputArea = document.getElementById('output-textarea');

  outputArea.value = '';
  document.getElementById('total-execution-time').innerText = '-';
  initServerCommunication(inputArea.value);
}

function initServerCommunication(data) {
  const url = window.location.origin.replace("http", "ws");
  let socket = new WebSocket(`${url}/ws`);

  socket.onopen = () => socket.send(data);
  socket.onmessage = (event) => processServerEvent(socket, event);

  socket.onclose = (event) => {
    if (event.wasClean) {
      console.log('Server connection successfully dropped')
    } else {
      console.log('Server connection killed')
    }
  };

  socket.onerror = function(error) {
    console.error(error)
  };
}

function processServerEvent(socket, event) {
  console.log("Server event: ", event.data);

  let [cmd, text] = (event.data || "").split(" > ");

  switch(cmd.trim().toLowerCase()) {
    case 'error':
      handleServerError(text);
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

function handleServerError(text) {
  console.error(text);
}

function handleServerStart() {
  let startButton = document.getElementById('start-button');
  startButton.setAttribute('disabled', true);
}

function handleServerFinish(socket, text) {
  socket.close();

  document.getElementById('start-button').removeAttribute('disabled');
  document.getElementById('total-execution-time').innerText = text;
}

function handleItemProcessed(text) {
  document.getElementById('output-textarea').value += `${text}\n\n`;
}
