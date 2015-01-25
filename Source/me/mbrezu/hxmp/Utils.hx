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

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Error;
import sys.net.Socket;

class Utils
{

	private function new() 
	{
		
	}
	
	public static function writeString(socket: Socket, str: String) {
		var b = Bytes.ofString(str);
		var blen = new BytesOutput();
		blen.writeInt32(b.length);
		writeBytes(socket, blen.getBytes());
		writeBytes(socket, b);
		socket.output.flush();
	}
	
	public static function readString(socket: Socket): String {
		var len = new BytesInput(readBytes(socket, 4), 0, 4).readInt32();
		return readBytes(socket, len).getString(0, len);
	}
	
	private static function writeBytes(socket: Socket, bytes: Bytes) {
		var pos = 0;
		while (pos < bytes.length) {
			var len = bytes.length - pos;
			var bytesWritten = 0;
			try {
				bytesWritten = socket.output.writeBytes(bytes, pos, len);
			} catch (any: Dynamic) { }
			if (bytesWritten > 0) {
				pos += bytesWritten;
			} else {
				waitForWrite(socket, 1.0);
			}
		}
	}
	
	private static function waitForWrite(socket: Socket, timeout: Float) {
		//trace("waiting for write");
		var result = Socket.select(null, [socket], null, timeout);
		var canWrite = result.write != null && result.write.length > 0 && result.write[0] == socket;
		if (!canWrite) {
			trace("can't write");
			throw Error.Blocked;
		}		
	}
	
	private static function waitForRead(socket: Socket, timeout: Float) {
		//trace('waiting for read, timeout = $timeout');
		var result = Socket.select([socket], null, null, timeout);
		var canRead = result.read != null && result.read.length > 0 && result.read[0] == socket;
		//trace(result.read, socket);
		if (!canRead) {
			trace("can't read");
			throw Error.Blocked;
		}		
	}
	
	private static function readBytes(socket: Socket, len: Int): Bytes {
		var b = Bytes.alloc(len);
		var pos = 0;
		var socketReportedReady = false;
		while (len > 0) {
			var bytesRead = 0;
			try {
				bytesRead = socket.input.readBytes(b, pos, len);
			}
			catch (ex: Eof) {
			}
			//trace('$bytesRead bytes read');
			if (bytesRead == 0) {
				if (socketReportedReady) {
					throw Error.Blocked;
				} else {
					waitForRead(socket, 1.0);				
					socketReportedReady = true;
				}
			} else {
				len -= bytesRead;
				pos += bytesRead;
				socketReportedReady = false;
			}
		}
		return b;
	}
	
}