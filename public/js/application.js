function startProcessingClicked() {
  let area = document.getElementById('input-textarea');
  let urls = area.value;

  initServerCommunication(urls);
}

function initServerCommunication(data) {
  let socket = new WebSocket("ws://localhost:3000/ws");

  socket.onopen = () => socket.send(data);
  socket.onmessage = (event) => processServerEvent(event);

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

function processServerEvent(event) {
  // TODO: handle case when | is part of the URL
  let [cmd, text] = (event.data || "").split(" | ");

  switch(cmd.trim().toLowerCase()) {
    case 'error':
      handleServerError(text);
      break;
    case 'start':
      handleServerStart();
      break;
    case 'finish':
      handleServerFinish(text);
      break;
    case 'process':
      handleItemProcessed(text);
      break;
    default:
      console.error(`invalid command: '${cmd}'`);
  }
}

function handleServerError(text) {
  console.err(text);
}

function handleServerStart() {
  let startButton = document.getElementById('start-button')[0];
  startButton.setAttribute('disabled', true);
}

function handleServerFinish(text) {
  let startButton = document.getElementsByTagName('button')[0];
  startButton.setAttribute('disabled', false);

  // TODO: set total execution time
}

function handleItemProcessed(text) {
  let newItem = document.createElement('p');
  newItem.innerText = text;

  document.getElementById('output-container').appendChild(newItem);
}
