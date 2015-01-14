package me.mbrezu.hxmp;

#if neko
import neko.vm.Thread;
#elseif windows
import cpp.vm.Thread;
#end

import sys.io.File;
import sys.net.Host;
import sys.net.Socket;

interface IServerState {
	function getState(): String;
	function handleCommand(command: String): String;
	function mainLoop(): String;
}

enum CommandMessage {
	Command(command: String);
	Socket(socket: Socket);
	RemoveThread(thread: Thread);
	Quit;
}

enum UpdateMessage {
	Update(update: String);
	Quit;
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
		var updaters = new Array<Thread>();
		while (true) {
			var msg = Thread.readMessage(false);
			if (msg != null) {
				trace("msg", msg, updaters.length);
				if (!handleMessage(cast(msg, CommandMessage), updaters)) {
					return;
				}
			} else {
				Sys.sleep(0.01);
				broadcastUpdate(UpdateMessage.Update(state.mainLoop()), updaters);
			}
		}
	}
	
	private function handleMessage(message: CommandMessage, updaters: Array<Thread>) {
		switch (message) {
			case CommandMessage.Command(command): {
				broadcastUpdate(UpdateMessage.Update(state.handleCommand(command)), updaters);
				return true;
			}
			case CommandMessage.Socket(socket): {
				trace("subscribing");
				socket.setFastSend(true);
				var newThread = Thread.create(function() {
					updaterProc(socket);
				});
				updaters.push(newThread);
				trace(updaters.length);
				newThread.sendMessage(UpdateMessage.Update(state.getState()));
				return true;
			}
			case Quit: {
				broadcastUpdate(UpdateMessage.Quit, updaters);
				return true;
			}
			case RemoveThread(thread): {
				trace(updaters.length);
				updaters.remove(thread);
				trace(updaters.length);
				return updaters.length > 0;
			}
		}
	}
	
	private function updaterProc(socket: Socket) {
		try {
			while (true) {
				var msg = Thread.readMessage(true);
				switch (cast(msg, UpdateMessage)) {
					case Update(update): if (update != null) {
						trace(update);
						Utils.writeString(socket, update);
						trace("sent, waiting for ack");
						socket.setTimeout(0.5);
						var reply = Utils.readString(socket);
						trace(reply);
						if (reply != "ack") {
							break;
						}
					}
					case Quit: break;
				}
			}
		} catch (any: Dynamic) {
			trace(Type.typeof(any));
		}
		updatesThread.sendMessage(CommandMessage.RemoveThread(Thread.current()));		
	}
	
	private function broadcastUpdate(update: UpdateMessage, updaters: Array<Thread>) {
		for (updater in updaters) {
			updater.sendMessage(update);
		}
	}
	
	private function listenOn(port: Int, action: Socket -> Void) {
		var socket = new Socket();
		socket.bind(new Host("0.0.0.0"), port);
		socket.listen(5);
		while (true) {
			action(socket.accept());
		}		
	}
	
	private function updatesListener() {
		listenOn(portUpdates, function(socket) {
			trace("accepting updates");
			updatesThread.sendMessage(CommandMessage.Socket(socket));
		});
	}
	
	private function commandsListener() {
		listenOn(portCommands, function(socket) {
			trace("accepting commands");
			Thread.create(function() {
				while (true) {
					try {
						socket.setTimeout(10);
						var command = Utils.readString(socket);
						trace(command);
						updatesThread.sendMessage(CommandMessage.Command(command));
					} catch (any: Dynamic) {
						trace(Type.typeof(any));
						return;
					}
				}
			});
		});
	}	
}