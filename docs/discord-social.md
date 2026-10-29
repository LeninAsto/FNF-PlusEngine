# Discord Social SDK

Plus Engine uses `hxDiscordSocial` and the official Discord Social SDK on
Windows x64. The legacy `hxdiscord_rpc` dependency and its background callback
thread are no longer used.

## Building

Download the Discord Social SDK separately, then set its location before
building:

```powershell
$env:DISCORD_SOCIAL_SDK_DIR = 'C:\path\to\discord_social_sdk'
haxelib run lime build windows -debug
```

The build links the SDK from that external directory and copies
`discord_partner_sdk.dll` next to `PlusEngine.exe`. SDK binaries and headers
must not be committed to this repository.

## Mod application ID

A mod may select its Discord application in `pack.json`:

```json
{
  "discordApplicationId": "123456789012345678"
}
```

The former `discordRPC` pack field is not supported.

## Lua API

```lua
discordInitialize(applicationId)
discordSetPresence(details, state, smallImageKey, startTimestamp, endTimestamp, largeImageKey)
discordClearPresence()
discordShutdown()
```

`startTimestamp` and `endTimestamp` are optional absolute Unix timestamps in
seconds. The former `changeDiscordPresence` and `changeDiscordClientID`
callbacks are not supported.

## Authentication status

Rich Presence uses Discord's local client connection and does not require a
game login. Account authentication is a separate OAuth2 flow. It requires
Developer Portal configuration, token exchange and secure token persistence;
it will be added as a separate `Authentication` service instead of being mixed
into Presence. Never embed a Discord client secret in the game executable.
