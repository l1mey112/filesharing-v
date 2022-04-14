import os
import crypto.rand
import term

import compress.zlib

import rand

import net.websocket
import log

import crypto.aes
import arrays

fn invalid(){
	println(term.red("! Invalid command"))
	println(term.green("? call help"))
}

fn decorate(this string)string{
	return term.red(this)
}
fn cdecorate(this string)string{
	return term.green(this)
}

fn help(){
	print(term.blue("\n ()()() ")) print("\n")
	print(term.blue(" ()[]() ")) print(term.red("$ l-m.dev, v0.0.1\n"))
	print(term.blue(" ()()() ")) print("\n\n")

	terms := ["send","listen","reset","list","unpack","add","help"]
	print("Commands: ")
	for i, g in terms {
		print(term.green(g))
		if i != terms.len-1 {
			print(", ")
		}
	}

	send := cdecorate("send")
	listen := cdecorate("listen")
	bucket := decorate("vbucket")
	reset := cdecorate("reset")
	list := cdecorate("list")
	unpack := cdecorate("unpack")
	vkey := decorate(".vkey")
	vbytes := decorate(".vbytes")
	add := cdecorate("add")

	ega := decorate("file.txt.vbytes")
	egb := decorate("file.txt.vkey")
	egc := decorate("file.txt")
	server := decorate(".server")
	wss := decorate("wss://sockets.l-m.dev")


	print(
"

This is a simple tool to send and receive encrypted files over a websocket.
Files are encrypted using AES, and your own key used to encrypt the file is 
stored locally, next to executable as $vkey

Use $send to send a file, and $listen to receive files
When sending a file, it will compress and encrypt the files bytes and send 
them over the websocket.

Succesfully sending a file will create a $vkey file with the key used to
encrypt it, eg $egb
Send this file to the receiver, and they will be able to decrypt it.

The \"bounce server\" will relay the file to all clients indiscriminately, 
therefore it must wait for a response back to delete the lockfile created 
alongside the key. Placing a $server file in the $bucket directory with
the URL of another bounce server will will override the default server,
which is $wss

When receiving a file, it will listen for any incoming files and store them 
in the $bucket directory with the extension $vbytes

To list all files in the $bucket directory, use $list

Use $add to add a new key to the local bucket, for decrypting a file with 
the same base name

Then, use $unpack to decrypt all files in the $bucket directory, and place 
them in the current directory

For example, $add $egb will add a key for received file $ega 
to later decrypt into $egc using $unpack

Use $reset to change your encryption key
")

	exit(0)
}

fn ps(this string)string{
	return os.resource_abs_path(this)
}

fn main(){
	terms := ["send","listen","reset","list","unpack","add","help"]

	bucket()
	key()

	if os.args.len == 1 || os.args[1] !in terms{ 
		// example of if statement short circuiting!
		invalid()
		exit(1)
	}

	if os.args[1] == "help" {help()}
	println(term.blue("()[]() $ l-m.dev, v0.0.1"))

	if os.args[1] == "listen" {listen()}
	if os.args[1] == "send" {send()}
	if os.args[1] == "reset" {changekey()}
	if os.args[1] == "list" {listbucket()}
	if os.args[1] == "unpack" {unpack()}
	if os.args[1] == "add" {addkey()}
}

fn pfilename(arg string)string{
	return os.base(os.join_path_single(os.getwd(), arg))
}

fn pfilepath(arg string)string{
	return os.join_path_single(os.getwd(), arg)
}

fn serveruri()string{
	server := os.read_file(ps("vbucket/.server")) or {
		return "wss://sockets.l-m.dev"
	}
	return server
}

fn addkey(){
	//! check if ONLY a file, then copy

	if os.args.len != 3 {
		println(term.red("! no file specified"))
		println(term.green("? call help, or help add"))
		exit(1)
	}

	if !os.is_file(os.args[2]) || !os.is_readable(os.args[2]){
		println(term.red("! file does not exist or is not readable"))
		println(term.green("? call help, or help add"))
		exit(1)
	}

	if !os.args[2].contains(".vkey"){
		println(term.red("! file does not have the .vkey extension"))
		println(term.green("? call help, or help add"))
		exit(1)
	}

	bytes := os.read_bytes(os.args[2]) or {
		panic("could not read file")
	}
	if bytes.len != 32{
		println(term.red("! key is not 32 bytes in length, therefore invalid"))
		println(term.green("? call help, or help add"))
		exit(1)
	}

	filename := pfilename(os.args[2])

	os.write_file_array(ps("vbucket/"+filename), bytes) or {
		panic("failed to write key to bucket!")
	}

	println(term.red("! key ")+term.blue("\""+filename+"\"")+term.red(" added to bucket!"))
}

fn bucket() []string{
	if !os.is_dir(ps("vbucket")) {
		println(term.magenta("! creating bucket"))
		os.mkdir(ps("vbucket")) or {
			panic("could not create bucket")
		}
	}

	return os.walk_ext(ps("vbucket/"),"")
}

fn listbucket(){
	files := os.walk_ext(ps("vbucket/"),"")
	if files.len == 0 {
		println(term.magenta("& bucket is empty"))
	}
	for st in files {
		se := pfilename(st)
		println(term.magenta("& $se"))
	}
}

fn clearbucket(){
	for ft in os.walk_ext(ps("vbucket"),"") {
		os.rm(ft) or {
			panic("failed to remove file!")
		}
	}
	println(term.green("bucket cleared"))
}

fn key() []byte {
	key := os.read_bytes(ps(".vkey")) or {
		println(term.green("! .vkey not found, generating new key"))
		mut key := rand.bytes(32) or {
			panic("error generating key")
		}

		id := rand.uuid_v4().bytes() // 36 bytes
		key << id

		os.write_file_array(ps(".vkey"), key) or {
			panic("failed to write .vkey")
		}

		returnkey := os.read_bytes(ps(".vkey")) or {
			panic("failed to read .vkey")
		}
		return returnkey[..32]
	}
	return key[..32]
}

fn changekey(){
	println(term.green("? generating... "))
	mut key := rand.bytes(32) or {
		panic("error generating key")
	}

	id := rand.uuid_v4().bytes() // 36 bytes
	key << id

	os.write_file_array(ps(".vkey"), key) or {
		panic("failed to write .vkey")
	}
	println(term.red("! key reset, ")+term.blue("\".vkey\""))
}

fn id() string{
	key := os.read_bytes(ps(".vkey")) or {
		panic("error reading .vkey")
	}
	return key[32..].bytestr()
}

fn send(){
	if os.args.len < 3 {
		println(term.red("! no file specified"))
		println(term.green("? call help, or help send"))
		exit(1)
	}

	filename := pfilename(os.args[2])

	if filename.substr(0,1) == "." {
		println(term.red("! sent file name cannot start with a period!"))
		println(term.green("? call help, or help send"))
		exit(1)
	}

	strdata := pfilepath(os.args[2])
	if strdata == "" {return}
	mut data := readthis(strdata)
	if data == '\x00'.bytes() {return} //! failed to read

	mut client := start_client() or {
		if os.is_file(ps("vbucket/.server")) {
			panic("failed to connect to bounce server! check .server file for correct server address")
		} else {
			panic("failed to connect to bounce server!")
		}
	} //! start connection

	println(term.blue("$ writing key..."))
	os.write_file_array(ps("vbucket/"+filename+".vkey"),key()) or {
		panic("failed to write x.vkey!")
	}

	println(term.blue("$ encrypting..."))
	crypt := encrypt(mut data, key())
	mut name := filename.bytes()
	for _ in 0 .. name.len % 40 {
		name << '\x00'.bytes()
	} //! pad to 40 bytes

	name << crypt
	//! send data with file extension padded with 40 bytes

	println(term.blue("$ writing lockfile..."))
	os.write_file(ps("vbucket/"+filename+".lock"),"") or {
		panic("failed to write lockfile!")
	}

	println(term.blue("$ sending..."))
	client.write(name,websocket.OPCode.binary_frame) or {
		println(term.red("failed to send"))
		return
	}

	println(term.green("\n! sent"))

	println(term.green("? waiting for bounce..."))
	for true {}
}

fn unpack(){
	if bucket().len == 0 {
		println(term.magenta("\n& bucket is empty"))
		return
	}
	mut diddel := false

	println(term.green("\n& attempting to traverse and decrypt files\n"))
	for f in bucket(){
		if f.contains("lock.") {continue}
		if f.contains(".vkey") {continue}

		print(term.red(pfilename(f)+" ? "))
		
		if !f.contains(".vbytes") {continue} //* search for applicable keyfile

		if os.is_file(f[..f.len-7]+".vkey") {
			print(term.magenta("yes!"))

			filedata := os.read_bytes(f) or {
				panic("failed to read file!")
			}

			key := os.read_bytes(f[..f.len-7]+".vkey") or {
				panic("failed to read key!")
			}
			filename := pfilename(f[..f.len-7])

			os.write_file_array(pfilepath(filename),decrypt(filedata,key)) or {
				panic("failed to decrypt file")
			}

			print(term.blue(" > written \""+filename+"\""))

			os.rm(f) or {
				panic("failed to remove vbytes!")
			}
			os.rm(f[..f.len-7]+".vkey") or {
				panic("failed to remove vkey!")
			}

			diddel = true

		}else{
			print(term.magenta("no. "))
		}
		
		println("")
	}
	if diddel {
		println(term.green("\n& files decrypted and source files removed from the bucket"))
	}
}

fn readthis(this string) []byte {
	if pfilename(this).bytes().len > 39 {
		println(term.red("! filename too long"))
		println(term.green("? call help, or help send"))
		return '\x00'.bytes()
	}

	filebytes := os.read_bytes(this) or {
		println(term.red("! failed to read file"))
		println(term.green("? call help, or help send"))
		return '\x00'.bytes()
	}
	return filebytes
}

fn encrypt(mut data []byte, key []byte) []byte {
	cipher := aes.new_cipher(key)

	if data.len % 16 != 0 {
		for _ in 0 .. data.len % 16 {
			data << '\x00'.bytes()
		}
	} // set byte length to 16-byte blocks
	
	chunks := arrays.chunk(data,16)
		// chunks = byte[][]
		// split into 16-byte chunks
	mut encryptedlist := []byte{}

	for i in 0 .. chunks.len {
		mut encrypted := []byte{len: aes.block_size}
		cipher.encrypt(mut encrypted, chunks[i])
		encryptedlist << encrypted
	}

	compressed := zlib.compress(encryptedlist) or {
		panic("failed to compress")
	}

	return compressed
}

fn decrypt(data []byte, key []byte) []byte {
	cipher := aes.new_cipher(key)

	decompressed := zlib.decompress(data) or {
		panic("failed to decompress")
	}

	chunks := arrays.chunk(decompressed,16)
	mut decryptedlist := []byte{}

	for i in 0 .. chunks.len {
		mut decrypted := []byte{len: aes.block_size}
		cipher.decrypt(mut decrypted, chunks[i])
		decryptedlist << decrypted
	}

	for i in decryptedlist.len-16 .. decryptedlist.len {
		if decryptedlist[i] == '\x00'.bytes()[0] {
			index := i
			decryptedlist = decryptedlist[0..index]
			break
		}
	} // remove byte padding

	return decryptedlist
}

fn trim_nullb(st string) string {
	this := st.bytes()

	for i in 0 .. this.len {
		if this[i] == '\x00'.bytes()[0] {
			return this[0..i].bytestr()
		}
	}
	return this.bytestr()
} //* trims all null bytes (\0) from the end of a string

fn listen(){
	start_client() or {
		if os.is_file(ps("vbucket/.server")) {
			panic("failed to connect to bounce server! check .server file for correct server address")
		} else {
			panic("failed to connect to bounce server!")
		}
	}

	println(term.green("& listening! ctrl-c to exit..."))
	for true {}
}

fn start_client() ?&websocket.Client {
	mut ws := websocket.new_client(serveruri())?
	ws.logger.set_level(log.Level.disabled)
		//! disable logging

	// mut ws := websocket.new_client('wss://echo.websocket.org:443')?
	// use on_open_ref if you want to send any reference object
	ws.on_open(fn (mut ws websocket.Client) ? {
		/* println(term.green('websocket connected to the server and ready to send messages...')) */
	})
	// use on_error_ref if you want to send any reference object
	ws.on_error(fn (mut ws websocket.Client, err string) ? {
		println(term.red('\n\nconnection error : $err'))
		println(term.red('server may have been terminated'))
		exit(1)
	})
	// use on_close_ref if you want to send any reference object
	ws.on_close(fn (mut ws websocket.Client, code int, reason string) ? {
		println(term.green('the connection to the server successfully closed'))
	})
	// on new messages from other clients, display them in blue text
	ws.on_message(fn (mut ws websocket.Client, msg &websocket.Message) ? {
		if msg.payload.len < 0 {return}

		mut filename := msg.payload[0..40].bytestr()
		filename = trim_nullb(filename)

		if (ps("vbucket/"+filename+".lock")) in bucket() {
			os.rm(ps("vbucket/"+filename+".lock")) or {
				panic("failed to remove lockfile!")
			}
			println(term.red("\n! rebound! ")+term.blue("\""+filename+"\"")+term.red(" confirmed"))
			println(term.red("? "+term.blue("\""+filename+".vkey"+"\"")+term.red(" in the bucket for decryption")))
			exit(0)
		}

		data := msg.payload[40..]

		/* if filename in  {return} */
		os.write_file_array(ps("vbucket/"+filename+".vbytes"),data) or {
			panic("failed to write recived DATA!")
		}

		println(term.blue("? Got data! "+filename))
	})
	ws.connect() or {
		println(term.red('error on connection : $err'))
		if os.is_file(ps("vbucket/.server")) {
			panic("failed to connect to bounce server! check .server file for correct server address")
		} else {
			panic("failed to connect to bounce server!")
		}
		exit(1)
	}

	connection_type := if ws.is_ssl {term.green("SECURE")} else {term.red("INSECURE")}
	println(term.magenta("i $ws.uri : $connection_type \n"))

	go ws.listen()

	return ws
}