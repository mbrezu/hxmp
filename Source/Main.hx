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
		return "hello \n";
	}
	public function handleCommand(command: String): String {
		return command + "\n";
	}
	public function mainLoop(): String {
		Sys.sleep(0.01);
		return null;
	}
}

class Main extends Sprite {
	
	private static inline var COMMANDS_PORT = 12567;
	private static inline var UPDATES_PORT = 12568;
	
	public function new () {
		
		super ();
		trace("server");
		var server = new Server(COMMANDS_PORT, UPDATES_PORT, new ServerState() );
		//server.shutDown();
		var btnClient = new Button("Client", function() {
			var client = new Client("127.0.0.1", COMMANDS_PORT, UPDATES_PORT);
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