# Ladder
Ladder  A solution for the IWE (Immersive Wallless Experience) on iOS/MAC platform. 

## Features

* Hide VPN Icon
* PAC (Proxy auto-config)
    * Default URL: [https://git.io/gfwpac](https://git.io/fAPIe)
        * Powered by [GFWPAC](https://github.com/lincf0912/gfwpac/blob/master/gfwpac)
        * Default proxies (will try in order):
            * `SOCKS5 127.0.0.1:1081`
            * `SOCKS 127.0.0.1:1081`
            * `SOCKS5 127.0.0.1:1080`
            * `SOCKS 127.0.0.1:1080`
            * `DIRECT`
        * Almost no risk of being blocked (hosted on GitHub)
* Shadowsocks
    * Powered by [NEKit](https://github.com/zhuhaow/NEKit)
    * Multiple methods support:
        * `AES-128-CFB`
        * `AES-192-CFB`
        * `AES-256-CFB` **(RECOMMENDED)**
        * `ChaCha20`
        * `Salsa20`
        * `RC4-MD5`

## Requirements

* iOS 9.3+
* Xcode 9.3+
* [Apple Developer Program](https://developer.apple.com/programs)
* [Carthage](https://github.com/carthage/carthage)

## Installation

1. Check out the latest version of the project:

```bash
$ git clone https://github.com/lincf0912/Ladder.git
```

2. Open the `Ladder.xcodeproj`.

3. Build and run the `Ladder` scheme.

4. Enjoy yourself.

## License

This project is licensed under the Unlicense.

License can be found [here](LICENSE).
