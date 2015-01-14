package me.mbrezu.hxmp;

import sys.net.Host;
import sys.net.Socket;

#if neko
import neko.vm.Thread;
#elseif windows
import cpp.vm.Thread;
#end

class Client
{
	public function new(hostName: String, portCommands: Int, portUpdates: Int)  
	{
		Thread.create(function() {
			trace("client");
			var host = new Host(hostName);
			
			var updatesSocket = new Socket();
			updatesSocket.connect(host, portUpdates);
			updatesSocket.setFastSend(true);
			
			var commandsSocket: Socket = new Socket();
			commandsSocket.connect(host, portCommands);
			commandsSocket.setFastSend(true);
			//Sys.sleep(0.5);
			Utils.writeString(commandsSocket, "test");
			Utils.writeString(commandsSocket, "test");
			commandsSocket.close();
			
			trace("l1", Utils.readString(updatesSocket));
			Utils.writeString(updatesSocket, "ack");
			trace("l2", Utils.readString(updatesSocket));
			Utils.writeString(updatesSocket, "ack");
			trace("l3", Utils.readString(updatesSocket));
			Utils.writeString(updatesSocket, "ack");
			updatesSocket.close();					
		});
	}
	
}