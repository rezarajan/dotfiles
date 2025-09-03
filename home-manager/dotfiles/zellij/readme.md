### Loading Zjstatus

Sometimes the plugin may not load correctly; to fix this, simply open a zellij session and run:

```sh
zellij plugin -- https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm
```

This will prompt for the configuration; simply follow through and the plugin should load on the next boot of zellij.
If using Nix, replace the plugin locaion with the nix store location of the wasm file as shown [here](https://github.com/dj95/zjstatus/wiki/1-%E2%80%90-Installation#nix-flakes).
