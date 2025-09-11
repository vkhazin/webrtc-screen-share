const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const os = require("os");
const path = require("path");

const app = express();
const main = http.createServer(app);
const io = socketIo(main);

app.use(express.static(path.join(__dirname, 'public')));

let broadcasters = {}; // Store broadcaster peer connections

// Helper function to get server address (works better in Cloud Run)
function getServerAddress(req) {
    // In Cloud Run, use the request headers to determine the external URL
    const host = req.get('host');
    const protocol = req.get('x-forwarded-proto') || 'https';
    return `${protocol}://${host}`;
}

io.on("connection", (socket) => {
    console.log("New client connected:", socket.id);

    // Handle broadcaster event
    socket.on("broadcaster", () => {
        broadcasters[socket.id] = socket;
        console.log("Broadcaster added:", socket.id);
        socket.broadcast.emit("broadcaster"); // Notify viewers that a broadcaster exists
    });

    // Handle watcher event
    socket.on("watcher", () => {
        console.log("New viewer connected:", socket.id);
        Object.values(broadcasters).forEach((broadcasterSocket) => {
            broadcasterSocket.emit("watcher", socket.id);
        });
    });

    // Handle offer event
    socket.on("offer", (id, offer) => {
        io.to(id).emit("offer", socket.id, offer);
    });

    // Handle answer event
    socket.on("answer", (id, answer) => {
        io.to(id).emit("answer", socket.id, answer);
    });

    // Handle candidate event
    socket.on("candidate", (id, candidate) => {
        io.to(id).emit("candidate", socket.id, candidate);
    });

    // Handle broadcaster stopped sharing
    socket.on("broadcaster-stopped", () => {
        console.log("Broadcaster stopped sharing:", socket.id);
        delete broadcasters[socket.id];
        socket.broadcast.emit("broadcaster-stopped");
    });

    // Handle disconnect event
    socket.on("disconnect", () => {
        console.log("Client disconnected:", socket.id);
        delete broadcasters[socket.id];
        socket.broadcast.emit("broadcaster-disconnect", socket.id);
    });
});

// Route to return server URL (better for Cloud Run)
app.get("/ip", (req, res) => {
    // For Cloud Run, return the service URL instead of local IP
    const serverUrl = getServerAddress(req);
    const host = req.get('host');
    
    // Extract just the hostname for display
    const hostname = host ? host.split(':')[0] : 'localhost';
    
    res.json({ 
        ip: hostname,
        serverUrl: serverUrl,
        isCloudRun: !!req.get('x-cloud-trace-context') // Cloud Run specific header
    });
});

const PORT = process.env.PORT || 3000;
main.listen(PORT, () => console.log(`Server running on port ${PORT}`));
