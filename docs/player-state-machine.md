# Player State Machine Design

## Overview

The player controller uses a **Finite State Machine (FSM)** to manage player behavior. This design provides:
- **Clear separation of concerns** - each state handles its own logic
- **Easy extensibility** - new states can be added without modifying existing code
- **Maintainability** - state transitions are explicit and easy to understand
- **Testability** - input is gathered into a table, making it easy to mock

## States

### 1. IDLE
**Description**: Player is standing still, can face any direction (up/down/left/right)

**Enter**: Sets standing frame based on current facing direction

**Update Logic**:
1. **Priority 1**: Up/Down → Change facing, stay in IDLE
2. **Priority 2**: B + Left/Right (first press) → Transition to AUTO_WALKING
3. **Priority 3**: Left/Right (no B) → Transition to WALKING
4. **Default**: Stay in IDLE

**Transitions**:
- `IDLE` → `IDLE` (Up/Down pressed)
- `IDLE` → `WALKING` (Left/Right pressed without B)
- `IDLE` → `AUTO_WALKING` (B + Left/Right first press)

### 2. WALKING
**Description**: Player is manually walking left or right

**Enter**: Sets walk frame, resets animation counter

**Update Logic**:
1. **Priority 1**: Up/Down → Transition to IDLE (with new facing)
2. **Priority 2**: B pressed → Transition to AUTO_WALKING
3. **Priority 3**: Direction key released → Transition to IDLE
4. **Default**: Continue walking, animate, stay in WALKING

**Transitions**:
- `WALKING` → `IDLE` (Up/Down pressed or direction released)
- `WALKING` → `AUTO_WALKING` (B pressed)
- `WALKING` → `WALKING` (continue holding direction)

### 3. AUTO_WALKING
**Description**: Player is auto-walking to map edge

**Enter**: Sets walk frame, resets animation counter

**Update Logic**:
1. **Priority 1**: Up/Down → Transition to IDLE
2. **Priority 2**: Left/Right without B → Transition to WALKING
3. **Priority 3**: B + opposite direction → Change direction, stay in AUTO_WALKING
4. **Priority 4**: Edge reached → Transition to IDLE
5. **Default**: Continue auto-walking, animate, stay in AUTO_WALKING

**Transitions**:
- `AUTO_WALKING` → `IDLE` (Up/Down pressed or edge reached)
- `AUTO_WALKING` → `WALKING` (Left/Right without B)
- `AUTO_WALKING` → `AUTO_WALKING` (B + opposite direction or continue)

## State Diagram

```
         ┌─────────────┐
         │    IDLE     │◄─────────────┐
         └─────────────┘              │
           │  │  │  │                 │
           │  │  │  └─────────────────┤ (Up/Down)
           │  │  │                    │
           │  │  └──────────┐         │
           │  │             │         │
           │  │ (B+L/R)     │ (L/R)  │
           │  │             │         │
           │  ▼             ▼         │
           │ ┌──────────┐ ┌─────────┐│
           │ │  AUTO_   │ │ WALKING ││
           │ │ WALKING  │ │         ││
           │ └──────────┘ └─────────┘│
           │      │           │      │
           │      │           │      │
           └──────┴───────────┴──────┘
              (Edge/Up/Down)
```

## Implementation Details

### State Handler Structure

Each state has an `enter` and `update` method:

```lua
local stateHandlers = {
    [STATE_NAME] = {
        enter = function(self)
            -- Called when entering this state
        end,
        
        update = function(self, input)
            -- Called every frame while in this state
            -- Returns next state or current state to stay
            return nextState
        end,
    }
}
```

### Input Gathering

Input is gathered once per frame into a table:

```lua
{
    left = boolean,
    right = boolean,
    up = boolean,
    down = boolean,
    b = boolean,
    a = boolean,
}
```

### State Transitions

State transitions are handled by `changeState()`:
1. Calls `exit()` on old state (if exists)
2. Changes `self.state`
3. Calls `enter()` on new state (if exists)

### Main Update Loop

```lua
function Player:update()
    -- Gather input
    local input = self:gatherInput()
    
    -- Get current state handler
    local handler = stateHandlers[self.state]
    
    -- Update state and get next state
    local nextState = handler.update(self, input)
    
    -- Transition if needed
    if nextState ~= self.state then
        self:changeState(nextState)
    end
    
    -- Common post-processing (boundaries, camera, etc.)
end
```

## Benefits

1. **Extensibility**: Adding new states (e.g., MENU, COMBAT, CUTSCENE) is straightforward
2. **Clarity**: Each state's behavior is self-contained and easy to understand
3. **Maintainability**: No deep nesting of if-else statements
4. **Testability**: Input can be mocked for unit testing
5. **Debugging**: Current state is always visible in `self.state`

## Future Extensions

Potential new states to add:
- **MENU**: System menu (triggered by B button alone)
- **INTERACTING**: Talking to NPCs, using objects
- **COMBAT**: Battle mode
- **CUTSCENE**: Non-interactive sequences
- **DISABLED**: During dialogs (currently handled by `canMove` flag)

