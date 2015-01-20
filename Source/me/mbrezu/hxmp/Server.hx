/*
Copyright (c) 2015, Miron Brezuleanu
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package me.mbrezu.hxmp;

#if neko
import neko.vm.Thread;
#elseif windows
import cpp.vm.Thread;
#end

import sys.io.File;
import sys.net.Host;
import sys.net.Socket;
import haxe.CallStack;

interface IServerState {
	function getState(): String;
	function handleCommand(command: String): String;
	function mainLoop(): String;
}

enum CommandMessage {
	Command(command: String);
	Socket(socket: Socket);
	RemoveThread(thread: ThreadWrapper);
	Quit;
}

enum UpdateMessage {
	Update(update: String);
	Quit;
}

class ThreadWrapper {
	public var thread(default, default): Thread;
	public var id(default, null): Int;
	
	private static var idCounter = 0;
	
	public function new() {
		this.thread = null;
		idCounter++;
		this.id = idCounter;
	}
	
	public function removeFrom(array: Array<ThreadWrapper>) {
		for (elt in array) {
			if (elt.id == this.id) {
				array.remove(elt);
				break;
			}
		}
	}
}

class Server
{
	private var state: IServerState;
	private var updatesThread: Thread;
	private var portCommands: Int;
	private var portUpdates: Int;
	private var commandsListenerThread: Thread;
	private var updatesListenerThread: Thread;
	
	public function new(portCommands: Int, portUpdates: Int, state: IServerState)
	{
		this.portCommands = portCommands;
		this.portUpdates = portUpdates;
		this.state = state;
		updatesThread = Thread.create(updatesProc);		
		commandsListenerThread = Thread.create(commandsListener);
		updatesListenerThread = Thread.create(updatesListener);
	}	
	
	public function shutDown() {
		updatesThread.sendMessage(CommandMessage.Quit);
		commandsListenerThread.sendMessage(false);
		updatesListenerThread.sendMessage(false);
	}
	
	private function updatesProc() {
		var updaters = new Array<ThreadWrapper>();		
		while (true) {
			var msg = Thread.readMessage(false);
			if (msg != null) {
				if (!handleMessage(cast(msg, CommandMessage), updaters)) {
					return;
				}
			} else {
				var update = null;
				try {
					update = state.mainLoop();					
				} catch (any: Dynamic) {
					trace(any);
					for (line in CallStack.exceptionStack()) {
						trace(line);
					}
				}
				broadcastUpdate(UpdateMessage.Update(update), updaters);
			}
		}
	}
	
	private function handleMessage(message: CommandMessage, updaters: Array<ThreadWrapper>) {
		switch (message) {
			case CommandMessage.Command(command): {
				broadcastUpdate(UpdateMessage.Update(state.handleCommand(command)), updaters);
				return true;
			}
			case CommandMessage.Socket(socket): {
				var tw = new ThreadWrapper();
				var newThread = Thread.create(function() {
					updaterProc(socket, tw);
				});
				tw.thread = newThread;
				updaters.push(tw);
				var initialState = state.getState();
				newThread.sendMessage(UpdateMessage.Update(initialState));
				return true;
			}
			case Quit: {
				broadcastUpdate(UpdateMessage.Quit, updaters);
				return true;
			}
			case RemoveThread(thread): {
				updaters.remove(thread);
				return updaters.length > 0;
			}
		}
	}
	
	private function updaterProc(socket: Socket, tw: ThreadWrapper) {
		try {
			while (true) {
				var msg = Thread.readMessage(true);
				switch (cast(msg, UpdateMessage)) {
					case Update(update): if (update != null) {
						socket.setTimeout(2);
						socket.setBlocking(true);
						//trace("sending update", tw.id);
						Utils.writeString(socket, update);
						//trace("waiting for ack", tw.id);
						var reply = Utils.readString(socket);
						//trace("getting ack", tw.id, reply);
						if (reply != "ack") {
							break;
						}
					}
					case Quit: break;
				}
			}
		} catch (any: Dynamic) {
			//trace(Type.typeof(any));
		}
		//trace("************ closed client update socket", tw.id);
		socket.close();
		updatesThread.sendMessage(CommandMessage.RemoveThread(tw));		
	}
	
	private function broadcastUpdate(update: UpdateMessage, updaters: Array<ThreadWrapper>) {
		for (updater in updaters) {
			updater.thread.sendMessage(update);
		}
	}
	
	private function listenOn(port: Int, action: Socket -> Void) {
		var socket = new Socket();
		socket.bind(new Host("0.0.0.0"), port);
		socket.listen(5);
		while (true) {
			socket.setBlocking(false);
			try {
				var result = socket.accept();
				result.setBlocking(true);
				action(result);
			} catch (any: Dynamic) {
				//trace(Type.typeof(any));
				if (Thread.readMessage(false) == false) {
					socket.close();
					return;
				}
			}
			Sys.sleep(0.1);
		}
	}
	
	private function updatesListener() {
		listenOn(portUpdates, function(socket) {
			updatesThread.sendMessage(CommandMessage.Socket(socket));
		});
	}
	
	private function commandsListener() {
		listenOn(portCommands, function(socket) {
			Thread.create(function() {
				while (true) {
					try {
						socket.setTimeout(10);
						socket.setBlocking(true);
						var command = Utils.readString(socket);
						updatesThread.sendMessage(CommandMessage.Command(command));
					} catch (any: Dynamic) {
						//trace(Type.typeof(any));
						socket.close();
						//trace("closed client commands socket");
						return;
					}
				}
			});
		});
	}	
}