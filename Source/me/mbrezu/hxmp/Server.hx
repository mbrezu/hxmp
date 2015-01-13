package me.mbrezu.hxmp;

#if neko
import neko.vm.Thread;
#elseif windows
import cpp.vm.Thread;
#end

import sys.net.Host;
import sys.net.Socket;

interface IServerState {
	function getState(): String;
	function handleCommand(command: String): String;
	function mainLoop(): String;
}

enum UpdateMessage {
	Command(command: String);
	Socket(socket: Socket);
}

class Server
{
	private var state: IServerState;
	private var updatesThread: Thread;
	private var portCommands: Int;
	private var portUpdates: Int;
	
	public function new(portCommands: Int, portUpdates: Int, state: IServerState)
	{
		this.portCommands = portCommands;
		this.portUpdates = portUpdates;
		this.state = state;
		updatesThread = Thread.create(updatesProc);		
		Thread.create(commandsListener);
		Thread.create(updatesListener);
	}	
	
	private function updatesProc() {
		var updateSockets = new Array<Socket>();
		while (true) {
			var msg = Thread.readMessage(false);
			if (msg != null) {
				handleMessage(cast(msg, UpdateMessage), updateSockets);
			} else {
				Sys.sleep(0.01);
				broadcastUpdate(state.mainLoop(), updateSockets);
			}
		}
	}
	
	private function handleMessage(message: UpdateMessage, updateSockets: Array<Socket>) {
		switch (message) {
			case UpdateMessage.Command(command): {
				broadcastUpdate(state.handleCommand(command), updateSockets);
			}
			case UpdateMessage.Socket(socket): {
				updateSockets.push(socket);
				socket.output.writeString(state.getState());
			}
		}
	}
	
	private function broadcastUpdate(update: String, updateSockets: Array<Socket>) {
		if (update != null) {
			for (updateSocket in updateSockets) {
				updateSocket.output.writeString(update);
			}
		}
	}
	
	private function listenOn(port: Int, action: Socket -> Void) {
		var socket = new Socket();
		socket.bind(new Host("0.0.0.0"), port);
		socket.listen(1);
		while (true) {
			trace("listening on", port);
			action(socket.accept());
		}		
	}
	
	private function updatesListener() {
		listenOn(portUpdates, function(socket) {
			updatesThread.sendMessage(UpdateMessage.Socket(socket));
		});
	}
	
	private function commandsListener() {
		listenOn(portCommands, function(socket) {
			Thread.create(function() {
				while (true) {
					var command = socket.input.readLine();
					trace(command);
					updatesThread.sendMessage(UpdateMessage.Command(command));
				}
			});			
		});
	}	
}