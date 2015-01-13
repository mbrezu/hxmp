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
			var host = new Host(hostName);
			
			var updatesSocket = new Socket();
			updatesSocket.connect(host, portUpdates);

			var commandsSocket: Socket = new Socket();
			commandsSocket.connect(host, portCommands);
			commandsSocket.output.writeString("test\n");
			commandsSocket.close();
			
			trace(updatesSocket.input.readLine());
			trace(updatesSocket.input.readLine());
			updatesSocket.close();					
		});
	}
	
}