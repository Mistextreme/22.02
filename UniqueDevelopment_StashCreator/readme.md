# UniqueDevelopment Stash

Stash System for FiveM with an admin panel for easy management.

## 📋 Requirements

Before installing, make sure you have these resources running on your server:

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory) **OR** [qb-inventory](https://github.com/qbcore-framework/qb-inventory)
- [ox_target](https://github.com/overextended/ox_target) **OR** [qb-target](https://github.com/qbcore-framework/qb-target) *(if using target interaction)*

### Supported Frameworks
- ESX
- QBCore
- QBox (QBX)


## 🚀 Installation

### Step 1: Database Setup
Import the SQL file into your database:

1. Open your database management tool
2. Select your FiveM database
3. Run the following SQL query:

```sql
CREATE TABLE IF NOT EXISTS `unique_stashes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stash_id` VARCHAR(50) NOT NULL UNIQUE,
    `label` VARCHAR(100) NOT NULL,
    `slots` INT DEFAULT 100,
    `weight` INT DEFAULT 30000,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `size_x` FLOAT DEFAULT 0.6,
    `size_y` FLOAT DEFAULT 1.9,
    `size_z` FLOAT DEFAULT 2.0,
    `rotation` FLOAT DEFAULT 0.0,
    `code` VARCHAR(50) NOT NULL,
    `debug` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Step 2: Configure
Open `server/config.lua` and adjust settings to your liking:

```lua
Config.InteractionType = 'target'  -- 'target' or '3dtext'
Config.Command = 'StashCreator'    -- Command to open admin panel
Config.Keybind = 'F7'              -- Keybind to open admin panel

Config.AdminGroups = {
    'developer',
    'admin'
}
```

### Step 3: Add to Server Config
Add the following line to your `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory  # or qb-inventory
ensure ox_target     # or qb-target (optional)

ensure UniqueDevelopment_StashCreator
```

> ⚠️ **Important:** Make sure `UniqueDevelopment_StashCreator` starts AFTER the dependencies!

### Step 4: Restart Server
Restart your server

## 🎮 Usage

### Opening Admin Panel
- **Command:** `/StashCreator`
- **Keybind:** `F7` (default)

### Creating a Stash
1. Open the admin panel
2. Click "Create Stash" tab
3. Fill in the details:
   - **Stash ID:** Unique identifier (e.g., `police_storage`)
   - **Label:** Display name (e.g., `Police Storage`)
   - **Slots:** Number of inventory slots
   - **Weight:** Maximum weight capacity
   - **Code:** Password to access the stash
   - **Coordinates:** Click "My Position" to use your current location
4. Click "Create Stash"

### Managing Stashes
From the stash list, you can:
- 👁️ **View** - Inspect stash contents (admin only)
- ✏️ **Edit** - Modify stash settings
- 📍 **Teleport** - Teleport to stash location
- 🗑️ **Delete** - Remove the stash

## ⚙️ Configuration

### Webhooks (Discord Logging)
Configure Discord webhooks in `server/config.lua`:

```lua
Config.Webhooks = {
    stashOpen = "YOUR_WEBHOOK_URL",  -- Logs when stash is opened
    stashFail = "YOUR_WEBHOOK_URL",  -- Logs failed attempts
    adminLog = "YOUR_WEBHOOK_URL"    -- Logs admin actions
}
```

### Admin Permissions
Add admin groups in config or use ACE permissions:

```cfg
add_ace group.admin command.stashadmin allow
```

## 🔧 Troubleshooting

### Stashes not appearing?
1. Make sure the database table was created
2. Check if oxmysql is running
3. Restart the resource

### Target not working?
1. Verify ox_target or qb-target is running
2. Check `Config.InteractionType` is set to `'target'`

### Admin panel not opening?
1. Check if you have admin permissions
2. Try using the command instead of keybind

## 📞 Support

For issues and support, open a ticket on [Discord](https://discord.gg/bpWYsC5juV).
