package me.mbrezu.hxmp;

import haxe.io.Bytes;
import haxe.io.BytesData;
import sys.net.Socket;

class Utils
{

	private function new() 
	{
		
	}
	
	public static function writeString(socket: Socket, str: String) {
		var b = Bytes.ofString(str);
		socket.output.writeInt32(b.length);
		socket.output.writeString(str);
		socket.output.flush();
	}
	
	public static function readString(socket: Socket): String {
		var len = socket.input.readInt32();
		return socket.input.readString(len);
	}
	
}