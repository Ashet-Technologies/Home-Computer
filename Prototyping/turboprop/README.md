# Turboprop

Turboprop is a serial downloader and interface to the [Parallax Propeller 2](https://www.parallax.com/propeller-2/).

## Features

- Execute applications in RAM
- Start TAQOZ
- Start P2 Monitor
- Platform independent
- Configure clock mode
- Chainloader (Invoke application with stdio tied to the serial port to allow reusing the serial port)

Turboprop explicitly does not implement a *download to flash* feature, as its architecture allows this by utilizing chainloaders.

## Usage Examples

### Download application and execute

This is the most common use case: Reset the propeller, load a new application and run it right away:

```sh-session
[dev@hostname my-p2-project]$ turboprop -P /dev/ttyUSB1 application.bin
...
[dev@hostname my-p2-project]$ 
```

### Download application and open monitor

Turboprop ships a really basic monitor which forwards inputs to the propeller and prints what it sends on the serial port:

```sh-session
[dev@hostname my-p2-project]$ turboprop -P /dev/ttyUSB1 --monitor application.bin
...

```

### Download application with chain loader

A chainloader can be used to execute another program which operates on the serial port. This can be used to load programs to the flash:

```sh-session
[dev@hostname my-p2-project]$ turboprop -P /dev/ttyUSB1 flash-loader.bin ./p2-flash-loader.py application.bin
...
[dev@hostname my-p2-project]$ 
```

### Start interactive TAQOZ shell

Turboprop also allows starting TAQOZ, here shown in combination with `--monitor`:

```sh-session
[dev@hostname my-p2-project]$ turboprop -P /dev/ttyUSB1 --exec taqoz --monitor
...

```

### Start P2 Monitor with chainloader

It's also possible to start the internal P2 Monitor with `--exec monitor`, which can be combined with a chainloader.

In this example, you could for example create an application which serves the P2 monitor over a web interface:

```sh-session
[dev@hostname my-p2-project]$ turboprop -P /dev/ttyUSB1 --exec monitor ./p2-web-monitor.py localhost:8080
...

```

## Building

To build turboprop, you need [Zig 0.13.0](https://ziglang.org/download/) installed for your platform.

After that, you can just invoke

```sh-session
[dev@hostname my-p2-project]$ zig build
[dev@hostname my-p2-project]$ 
```

to build the software for your platform.
