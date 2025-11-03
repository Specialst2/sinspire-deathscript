# Sinspire Death System

A lightweight and configurable death & revive system for vMenu/FiveM servers.

### 🧠 Features
- Smooth death overlay and timers
- Customizable revive and respawn delays
- Hold-to-respawn keybind (`G` by default)
- Built-in `/revive` and `/respawn` commands
- ACE-based admin tools:
  - `/adrev [id]` → instantly revive yourself or another player
  - `/adres [id]` → instantly respawn yourself or another player at hospital
- Works seamlessly with vMenu or standalone setups

---

### ⚙️ Setup
1. Drop the folder into your `resources` directory.
2. Add this to your `server.cfg`: ensure sinspire_deathscript

### ⚒️ACE Perms
Make sure your admin group has permission to use the admin commands.

If using DiscordAcePerms or Badger_Discord_API with your staff role:

add_ace group. sinspire.adrev allow
add_ace group. sinspire.adres allow

