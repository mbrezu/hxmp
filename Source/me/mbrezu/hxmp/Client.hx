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

import sys.net.Host;
import sys.net.Socket;

#if neko
import neko.vm.Thread;
#elseif windows
import cpp.vm.Thread;
#end

interface IClientState {
	function handleUpdate(update: String): Void;
}

class Client
{
	private var clientState: IClientState;
	private var updatesSocket: Socket;
	private var commandsSocket: Socket;
	private var updatesThread: Thread;
	
	public function new(hostName: String, portCommands: Int, portUpdates: Int, clientState: IClientState)  
	{
		this.clientState = clientState;
		
		var host = new Host(hostName);
		updatesSocket = new Socket();
		updatesSocket.connect(host, portUpdates);
		commandsSocket = new Socket();
		commandsSocket.connect(host, portCommands);
		
		updatesThread = Thread.create(updateProc);
	}
	
	public function shutdown() {
		updatesThread.sendMessage(false);
	}
	
	public function sendCommand(command: String) {
		Utils.writeString(commandsSocket, command);
	}
	
	private function updateProc() {
		while(true) {
			try {
				updatesSocket.setTimeout(0.01);
				var update = Utils.readString(updatesSocket);
				//trace("done reading", update);
				//updatesSocket.setTimeout(0.5);
				Utils.writeString(updatesSocket, "ack");
				//trace("done acking");
				clientState.handleUpdate(update);
			} catch (any: Dynamic) {
			}
			if (Thread.readMessage(false) == false) {
				trace("closed client");
				updatesSocket.close();
				commandsSocket.close();
				return;
			}
		}
	}
	
}