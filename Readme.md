
# HXMP

## (Short) Description

A Haxe multiplayer network library.

## Architecture

This library is only usable in games that:

 * use multiplayer in a local network;
 * are written with haxe using the `neko` or `cpp` platforms.
 
It implements a very simple approach: 

 * there is a server where the game loop runs and there are clients
   that send commands to the server and receive updates;
 * when a client connects to the server it receives the current state
   of the world;
 * all updates are broadcasted to all clients;
 * updates are generated by client commands or from the server's main
   loop;
 * all commands and updates are strings;
 * clients must send keep-alive commands or they will be disconnected.

## Example

See `Main.hx` for a very simple example.

## Usage

To use this code you need to implement two interfaces: `IServerState`
and `IClientState`.

### `IServerState` methods

 * `getState` - should return a string representation of the current
   state of the server; called when a client connects for the first
   time to give the client the initial state of the world;
 * `handleCommand` - called when a command is received; can return an
   update to the server state caused by handling the command or `null`
   for no update;
 * `mainLoop` - called continously when there are no commands; returns
   updates to the server state or `null` for no update; should include
   a `Sys.sleep` if it doesn't use all the time allocated for
   processing one frame.
   
### `IClientState` methods

 * `handleUpdate` - should handle an update broadcasted from the
   server;
   
### `Server`/`Client` usage
   
To create a server use the `Server` constructor (see `Main.hx`
for an example). Arguments: the ports for commands and for updates and
a `IServerState` instance.

Servers can be shutdown using `Server.shutdown`. `Sys.sleep` a little
after calling this method to make sure that bound sockets have been
freed.

To create a client use the `Client` constructor (see `Main.hx` for an
example). Arguments: the hostname to connect to, the ports for
commands and updates and an instance of `IClientState`.

Clients can be shutdown using `Client.shutdown`. Commands can be sent
using `Client.sendCommand`. 

`IClientState.handleUpdate` will be called automatically whenever the
server sends an update. Caution: the call will occur on a worker
thread, so if you have to interact with the UI etc. you need to make
the necessary arrangements in `handleUpdate` to send the update to the
proper thread.

## License

This code is hereby placed under the BSD two-clause license (see file
`License.txt`).
