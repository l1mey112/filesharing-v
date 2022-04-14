// Importing the required modules
const WebSocketServer = require('ws');
const http = require("http");

const port = 9988
let app = require('./http');

const server = http.createServer(app);
const wss = new WebS.Server({ server });

// Creating connection using websocket
wss.on("connection", ws => {
    console.log("new client connected");
    // sending message
    ws.on("message", data => {
        console.log(`got data, relaying!`)
        wss.clients.forEach(function each(client) {
            client.send(data);
        });
    });
    // handling what to do when clients disconnects from server
    ws.on("close", () => {
        console.log("the client has DISconnected");
    });
    // handling client connection error
    ws.onerror = function () {
        console.log("Some Error occurred")
    }
});
server.listen(port, function () {
    console.log(`Server is listening on ${port}!`);
});