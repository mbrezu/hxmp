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
package;


import me.mbrezu.hxmp.Client;
import me.mbrezu.hxmp.Server;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.display.Sprite;
import openfl.text.TextFieldAutoSize;
import sys.net.Socket;

class Button extends Sprite {
	public function new(text: String, action: Void -> Void) {
		super();
		var textField = new TextField();
		textField.selectable = false;
		textField.autoSize = TextFieldAutoSize.LEFT;
		textField.backgroundColor = 0xaacc44;
		textField.background = true;
		textField.text = text;
		textField.scaleX = 2;
		textField.scaleY = 2;
		textField.border = true;
		textField.borderColor = 0x0;
		textField.addEventListener(MouseEvent.CLICK, function(e) {
			action();
		});
		addChild(textField);
	}
}

class ServerState implements IServerState {
	public function new() {
	}
	
	public function getState(): String {
		return "hello";
	}
	public function handleCommand(command: String): String {
		return 'echo: $command';
	}
	public function mainLoop(): String {
		Sys.sleep(0.01);
		return null;
	}
}

class ClientState implements IClientState {	
	
	var counter: Int;
	public var client: Client;
	
	public function new() {		
		counter = 0;
	}
	
	public function handleUpdate(update: String) {
		counter ++;
		trace(counter, update);
		if (counter == 3 && client != null) {
			client.shutdown();
		} else {
			client.sendCommand("test");
		}
	}
}

class Main extends Sprite {
	
	private static inline var COMMANDS_PORT = 12567;
	private static inline var UPDATES_PORT = 12568;
	
	public function new () {
		
		super ();
		trace("server");
		var server = new Server(COMMANDS_PORT, UPDATES_PORT, new ServerState());
		//server.shutDown();
		var btnClient = new Button("Client", function() {
			var clientState = new ClientState();
			var client = new Client("127.0.0.1", COMMANDS_PORT, UPDATES_PORT, clientState);
			clientState.client = client;
		});
		addChild(btnClient);
		var btnShutdown = new Button("Restart Server", function() {
			server.shutDown();
			Sys.sleep(1);
			server = new Server(COMMANDS_PORT, UPDATES_PORT, new ServerState() );
		});
		btnShutdown.x = 200;
		addChild(btnShutdown);
	}
}
