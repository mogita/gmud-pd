---
type: "always_apply"
---

# Original GMUD Reference (circa 2000)

The original gmud game is located at `/Users/mogita/Developer/gamesrc/gmud` and serves as the reference for gameplay, quests, dialogs, and game mechanics. This is a 6502 assembly game for a legacy platform.

**IMPORTANT**: Never modify the original gmud project. Use it only as a reference.

## Project Structure

```
/Users/mogita/Developer/gamesrc/gmud/src/
├── *.s              # Assembly source files (main game logic)
├── *.dat            # Data files (goods, skills)
├── h/               # Header files
│   ├── id.h         # Entity IDs (NPCs, items, classes)
│   ├── gmud.h       # Game constants and player stats
│   └── *.h          # Other headers
├── data/            # Game data files
│   ├── npc_data.gb  # NPC definitions (simplified Chinese)
│   ├── kf_data.gb   # Kung-fu/martial arts data
│   ├── map_data     # Map definitions
│   ├── perform.txt  # Combat moves/performances
│   └── image_*      # Sprite/image data
└── map*             # Map layout files
```

## Key Files for Reference

### Messages & Dialogs
- **`talk.s`** - Interactive object messages (well, sleep, items)
  - Contains messages shown when interacting with POIs
  - Example: `drink_succ_msg: db '你在井边用杯子舀起井水喝了几口',0`
  
- **`string.s`, `string2.s`, `stringx.s`, `stringy.s`** - Game text strings

### NPCs & Quests
- **`npc.s`** - NPC behavior and dialog logic
- **`npc_quest.s`** - Quest-related NPC interactions
- **`npc_quest.txt`** - Quest dialog text and NPC quest tables
- **`data/npc_data.gb`** - NPC definitions (name, stats, description)
  - Format: name, attributes, skills, description text

### Items & Goods
- **`goods.dat`** - Item definitions
- **`goods.s`** - Item logic and handling
- **`h/id.h`** - Item and entity ID constants

### Combat & Skills
- **`fight.s`** - Combat system
- **`skill.s`, `skill.dat`** - Skill definitions
- **`perform.s`** - Combat moves
- **`data/kf_data.gb`** - Kung-fu/martial arts data

### Game Systems
- **`game.s`** - Core game loop and player stats
- **`system.s`** - System mechanics (hunger, thirst decay)
- **`task.s`** - Task/quest system
- **`menu.s`** - Menu system

### Maps
- **`map1` through `map7`** - Map definitions
- **`scroll.s`** - Map scrolling logic
- **`data/map_data`** - Map metadata

## Searching for Content

### Finding Messages
```bash
# Search for Chinese text in assembly files
grep -rn "你" /Users/mogita/Developer/gamesrc/gmud/src/*.s

# Search for specific keywords
grep -rn "井\|水\|喝" /Users/mogita/Developer/gamesrc/gmud/src/
```

### Finding NPC Dialogs
```bash
# NPC dialog messages are often in npc_quest.txt or string*.s
grep -rn "NPC_NAME" /Users/mogita/Developer/gamesrc/gmud/src/npc_quest.txt
```

### Finding Item References
```bash
grep -rn "ITEM_NAME" /Users/mogita/Developer/gamesrc/gmud/src/goods.dat
grep -rn "ITEM_ID" /Users/mogita/Developer/gamesrc/gmud/src/h/id.h
```

## Text Encoding

- `.gb` files use simplified Chinese (GB2312 encoding)
- `.big5` files use traditional Chinese (Big5 encoding)
- Some assembly files contain inline Chinese text

## Common Patterns

### Message Display
Messages are typically stored as null-terminated strings:
```asm
message_name:
    db  '中文消息文本',0
```

### NPC Data Format (in npc_data.gb)
```
npc_name:
    db  'NPC名称',0,0,0    ; Name (padded)
    db  flags...           ; Various flags
    db  stats...           ; Combat stats
    db  'NPC描述文字.',0   ; Description
```

## Notes

- The code uses 6502 assembly with custom macros
- `scode` conditional determines simplified vs traditional Chinese
- Many files have both `.s` (assembly) and `.txt` (data) variants
- Explore incrementally - not all structures are fully documented
