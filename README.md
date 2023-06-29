# Logicboard - Code Execution and REPL over WebSockets
Logicboard lets you run a blob of code or start REPL via WebSockets. A typical use case is an in-browser code editor which can run code in multiple languages.

## How does it work?
The diagram below shows the overall architecture.
Logicboard internally runs your code/REPL in a separate docker container and interacts with it via a [pseudoterminal](https://en.wikipedia.org/wiki/Pseudoterminal).

When running REPL, you can simply send a `stdin` via websocket and receive the `stdout` in response. 

![logicboard flow diagram](/docs/images/flowchart.svg)


# Demo

![demo](/docs/images/demo.jpg)

This project consists of two parts:
- **Frontend**: A web app with code editor, built in React
- **Backend**: A websocket server that executes code, built in Elixir + Phoenix

## Running Locally
We prefer [asdf](https://asdf-vm.com) to manage runtime versions, please take a look at our [.tool-versions](/.tool-versions) for supported versions.

Else, please make sure the following languages are installed:
```bash
erlang 26.0
elixir 1.14.5
nodejs 16.13.2
yarn 1.22.19
```

You also need to install `docker` to generate language-specific images.

### Setup
Please make sure `docker` is running, then run:
```bash
mix setup
```

This will:
- Build Docker images for each language
- Fetch project dependencies

### Start the webapp and websocket server

- Run `mix phx.server`
- Visit [http://localhost:4000](http://localhost:4000) to launch the code editor
- A WebSocket server will also be started at: `ws://localhost:4000/socket/websocket`

# Websocket API
Logicboard provides an API to run code via websocket messages (aka Commands)

When connecting to the websocket server, you need to pass a Session ID, eg:

`ws://localhost:4000/socket/websocket?session_id=abcd`

Once the connection is established, you can start sending commands to run code or start REPL.

### The `run` command

When you ask logicboard to run code, it also needs a few other things:
- `language`: The programming language to use.
- `files`: A list of files with the code to execute.



The `files` parameter is used to create a directory structure for your code, think of it as `cloning` your repository.
- `main` (bool): Indicates this is the main file to run.
- `name` (string): Name of the file/directory.
- `directory` (bool): Whether the file is a directory.
- `content` (string or array): For a regular file, this contains the text content of the file. In case of directories, it will contain other files/directories as children.  

Consider the `run` command below, this will execute the contents of file `main.py` and return the result `Hello, world!` via `stdout`

## run
```json
{
	"event": "run",
	"payload": {
		"language": "python_3",
		"files": [{
			"main": true,
			"name": "main.py",
			"directory": false,
			"content": "print('Hello, world!')"
		}]
	}
}
```

## repl
Starts an interactive REPL session
```json
{
	"event": "repl",
	"payload": {
		"language": "python",
		"files": [{
			"main": true,
			"name": "main.py",
			"directory": false,
			"content": "<base 64 encoded>"
		}]
	}
}
```

## stdin
Sends a stdin input to the repl session

```json
{
	"event": "stdin",
	"payload": {
		"body": "help()"
	}
}
```

## stdout
Output from repl session or, result of a `run` command

```json
{
	"event": "stdout",
	"payload": {
		"body": "help()"
	}
}
```

## kill
Stops current execution, or a repl session

```json
{
	"event": "kill"
}
```

## stop
Sent by the server when an execution/repl is stopped
```json
{
	"event": "stop"
}
```

# Can I add more languages?
Of course you can! Logicboard just needs:
1. A Docker image to run
2. Command to compile your code
3. Command to start REPL (optional)

### 1. Create a dockerfile
Create a `<lang name>.dockerfile` inside [containers](https://github.com/logicboard/executor/tree/rename/containers)

Make sure your docker image has `bash` installed during build step.

We also need a user `app` with home directory `/home/app`

### 2. Update [languages.ts](https://github.com/logicboard/executor/blob/rename/assets/src/utils/languages.ts)
The `languages.ts` file used by the web app to display a list of lanugaues

Update the `languages.ts` with a few details:
- `name`: Name of your language
- `version`: Language version
- `code`: Language code - an identifier for your language
- `repel`: A boolean to indicate whether your language supports REPL
- `example`: A sample code that will be populated in the editor when your language is selected
- `main_file`: Name of your main file
- `message`: A placeholder message that will be displayed in the output area when your language is slected

### 3. Create your \<language\>.ex module
The `<language>.ex` module in [languages](https://github.com/logicboard/executor/tree/rename/lib/logicboard/languages) directory is used by the bakend for code execution. We'll need the following:
- `name`: The name of your language
- `version` Language version
- `container_image`: Ths function should return the image tag for your container. Use `<your docker file name>:executor`
- `run_command`: The command used to execute code in your main file
- `repl_command`: The command used to start REPL shell (or nil)

Once done, you also need to update the [languages.ex](https://github.com/logicboard/executor/blob/rename/lib/logicboard/languages/languages.ex) module:
- Add your language module to [alias](https://github.com/logicboard/executor/blob/rename/lib/logicboard/languages/languages.ex#L2)
- Add entry to the [@modules](https://github.com/logicboard/executor/blob/rename/lib/logicboard/languages/languages.ex#L10) map, where the `code` is the language code you specified in section #2 above

# Security Considerations
Containers are not a [sandbox](https://en.wikipedia.org/wiki/Sandbox_(computer_security)), and aren't safe for running arbitrary code, so please be careful!

