# filesharing-v
A way to securely send encrypted data to all machines "listening" for it. Written in V

The server folder contains the necessary skeleton for creating a dumb server that only relays incoming packets to all connections

[**Blog post**](https://blog.l-m.dev/posts/learning_v/)

## Help message

**Commands: send, listen, reset, list, unpack, add, help**

This is a simple tool to send and receive encrypted files over a websocket.
Files are encrypted using AES, and your own key used to encrypt the file is 
stored locally, next to executable as .vkey

Use **send** to send a file, and **listen** to receive files
When sending a file, it will compress and encrypt the files bytes and send 
them over the websocket.

Succesfully sending a file will create a .vkey file with the key used to
encrypt it, eg file.txt.vkey
Send this file to the receiver, and they will be able to decrypt it.

The "bounce server" will relay the file to all clients indiscriminately, 
therefore it must wait for a response back to delete the lockfile created 
alongside the key. Placing a .server file in the vbucket directory with
the URL of another bounce server will will override the default server,
which is **wss://sockets.l-m.dev**

When receiving a file, it will listen for any incoming files and store them 
in the vbucket directory with the extension .vbytes

To list all files in the vbucket directory, use **list**

Use **add** to add a new key to the local bucket, for decrypting a file with 
the same base name

Then, use **unpack** to decrypt all files in the vbucket directory, and place 
them in the current directory

For example, add file.txt.vkey will add a key for received file file.txt.vbytes 
to later decrypt into file.txt using unpack

Use **reset** to change your encryption key
