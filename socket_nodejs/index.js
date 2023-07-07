const app = require("express");
const http = require("http").createServer(app);
const { Server } = require("socket.io");
const io = new Server(http);

const PORT = 3700;

const destinationLocationEvent = "location_changed_destination";
io.on("connection", (socket) => {
  console.log("a user connected");
  socket.on(destinationLocationEvent, (location) => {
    console.log(destinationLocationEvent, location);
    io.emit(destinationLocationEvent, location);
  });

  socket.on("disconnect", () => {
    console.log("user disconnected");
  });
});

http.listen(PORT, () => {
  console.log(`listening on *:${PORT}`);
});
