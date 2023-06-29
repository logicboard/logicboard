import { nanoid } from "nanoid"
import { Message, Event, File } from "./messages"
import { PubSub } from "../utils/PubSub"

let socket: WebSocket | null = null


export enum SocketState {
    disconnected = 0,
    connecting = 1,
    connected = 2,
    disconnecting = 3,
}

export var State: SocketState = SocketState.disconnected

export const Socket = {
    connect(sessionId = nanoid()) {
        if (State == SocketState.connected) {
            return
        }

        State = SocketState.connecting
        PubSub.dispatch("ws:state", SocketState.connecting)

        if (socket) {
            socket.close()
        }
        socket = new WebSocket(`ws://localhost:4000/socket/websocket?session_id=${sessionId}`)

        socket.addEventListener("open", (event) => {
            State = SocketState.connected
            PubSub.dispatch("ws:state", SocketState.connected)
        });

        socket.addEventListener("close", (event) => {
            State = SocketState.disconnected
            PubSub.dispatch("ws:state", SocketState.disconnected)
        });

        socket.addEventListener("error", (error) => {
            PubSub.dispatch("ws:error", "error");
        });

        socket.addEventListener("message", (message) => {
            const { event, payload } = JSON.parse(message.data)
            PubSub.dispatch(`ws:${event}`, payload);
        });
    },

    send(message) {
        socket?.send(JSON.stringify(message));
    }
};

export default Socket;