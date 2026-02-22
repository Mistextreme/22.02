Config = {}

Config.Locale = 'en'
Config.TestCommands = true
Config.Debug = false

Config.HackGames = {
    ['power'] = {
        name = 'Power Routing',
        description = 'Reroute power systems using voltage formula',
        difficulty = 'Medium',
        enabled = false
    },
    ['firewall'] = {
        name = 'Firewall Bypass',
        description = 'Break through firewall protection',
        difficulty = 'Medium',
        enabled = false
    },
    ['memory'] = {
        name = 'Hex Scrambler',
        description = 'Decrypt memory patterns',
        difficulty = 'Medium',
        enabled = false
    },
    ['frequency'] = {
        name = 'Frequency Lockpick',
        description = 'Match signal frequencies',
        difficulty = 'Medium',
        enabled = false
    },
    ['packet'] = {
        name = 'Packet Chase',
        description = 'Intercept data packets',
        difficulty = 'Medium',
        enabled = false
    },
    ['voltage'] = {
        name = 'Voltage Balancer',
        description = 'Balance voltage levels',
        difficulty = 'Medium',
        enabled = false
    },
    ['security'] = {
        name = 'Security Override',
        description = 'Override security protocols',
        difficulty = 'Medium',
        enabled = false
    },
    ['quantum'] = {
        name = 'Quantum Switchboard',
        description = 'Quantum circuit manipulation',
        difficulty = 'Hard',
        enabled = false
    },
    ['bioscan'] = {
        name = 'Bioscan Spoofing',
        description = 'Spoof biometric scanners',
        difficulty = 'Medium',
        enabled = false
    },
    ['neural'] = {
        name = 'Neural Overload',
        description = 'Overload neural networks',
        difficulty = 'Hard',
        enabled = false
    },
    ['zeroday'] = {
        name = 'Zero-Day Assembly',
        description = 'Exploit zero-day vulnerabilities',
        difficulty = 'Very Hard',
        enabled = false
    },
    ['jam'] = {
        name = 'Packet Jam Frequency',
        description = 'Jam packet frequencies',
        difficulty = 'Medium',
        enabled = false
    },
    ['worm'] = {
        name = 'System Worm Trace',
        description = 'Trace system worms',
        difficulty = 'Medium',
        enabled = false
    },
    ['fracture'] = {
        name = 'Data Fracture',
        description = 'Fragment data structures',
        difficulty = 'Medium',
        enabled = false
    },
    ['magnetic'] = {
        name = 'Magnetic Relay',
        description = 'Control magnetic relays',
        difficulty = 'Medium',
        enabled = false
    },
    
    ['patternmemory'] = {
        name = 'Pattern Memory',
        description = 'Memorize pattern in 5x5 grid (7-10 cells, 3 sec)',
        difficulty = 'Medium',
        enabled = false
    },
    ['colorseq'] = {
        name = 'Color Sequence',
        description = 'Remember sequence of 6-8 colors',
        difficulty = 'Medium',
        enabled = false
    },
    ['mathchain'] = {
        name = 'Math Chain',
        description = 'Memorize 4 operations and calculate result',
        difficulty = 'Hard',
        enabled = false
    },
    ['symbolmatch'] = {
        name = 'Symbol Match',
        description = 'Memory card game - 10 pairs (20 cards, 30 attempts)',
        difficulty = 'Hard',
        enabled = false
    },
    ['pathmemory'] = {
        name = 'Path Memory',
        description = 'Trace memorized path through 6x6 grid',
        difficulty = 'Hard',
        enabled = false
    },
    ['numberseq'] = {
        name = 'Number Sequence',
        description = 'Find next number in sequence (hint available)',
        difficulty = 'Medium',
        enabled = false
    },
    ['logicgrid'] = {
        name = 'Logic Grid',
        description = 'Sudoku-style 3x3 grid puzzle',
        difficulty = 'Medium',
        enabled = false
    },
    ['mirrorcode'] = {
        name = 'Mirror Code',
        description = 'Memorize 6-char code and reverse it',
        difficulty = 'Easy',
        enabled = false
    },
    ['binarydec'] = {
        name = 'Binary Decoder',
        description = 'Convert 4 binary numbers to decimal',
        difficulty = 'Hard',
        enabled = false
    },
    ['cipherwheel'] = {
        name = 'Cipher Wheel',
        description = 'Decode 3 Caesar ciphers in a row (3 rounds total)',
        difficulty = 'Very Hard',
        enabled = false
    },
    ['flappybypass'] = {
        name = 'Flappy Bypass',
        description = 'Navigate through firewall nodes - Press SPACE to fly',
        difficulty = 'Hard',
        enabled = false
    },
    ['lockpick'] = {
        name = 'Lockpick',
        description = 'Pick the lock by listening to sound frequencies - 4 pins',
        difficulty = 'Hard',
        enabled = false
    },
    ['reaction'] = {
        name = 'Reaction Test',
        description = 'Click when target turns green - Must be faster than 500ms',
        difficulty = 'Medium',
        enabled = false
    },
    ['aimtrainer'] = {
        name = 'Aim Trainer',
        description = 'Click 10 targets before they disappear',
        difficulty = 'Hard',
        enabled = false
    },
    ['typeracer'] = {
        name = 'Type Racer',
        description = 'Type the phrase exactly in 15 seconds',
        difficulty = 'Medium',
        enabled = false
    },
    ['clickerrace'] = {
        name = 'Clicker Race',
        description = 'Click 50 times in 10 seconds',
        difficulty = 'Easy',
        enabled = false
    },
    ['arrowrhythm'] = {
        name = 'Arrow Rhythm',
        description = 'Press arrow keys in rhythm - 15 successful hits',
        difficulty = 'Hard',
        enabled = false
    },
    ['laserdodge'] = {
        name = 'Laser Dodge',
        description = 'Dodge 30 lasers using arrow keys',
        difficulty = 'Hard',
        enabled = false
    },
    ['mazerunner'] = {
        name = 'Maze Runner',
        description = 'Navigate through 8x8 maze in 30 seconds',
        difficulty = 'Medium',
        enabled = false
    },
    ['blockstacker'] = {
        name = 'Block Stacker',
        description = 'Stack 8 blocks perfectly - Press SPACE to drop',
        difficulty = 'Medium',
        enabled = false
    },
    ['simonsays'] = {
        name = 'Simon Says',
        description = 'Repeat color sequence for 5 rounds',
        difficulty = 'Medium',
        enabled = false
    },
    ['memorycards'] = {
        name = 'Memory Cards',
        description = 'Find all 8 pairs in 20 attempts',
        difficulty = 'Medium',
        enabled = false
    },
    ['soundmatch'] = {
        name = 'Sound Match',
        description = 'Repeat audio frequency sequence for 5 rounds',
        difficulty = 'Hard',
        enabled = false
    },
    ['stopwatch'] = {
        name = 'Stopwatch Challenge',
        description = 'Stop exactly at 5.000 seconds (±100ms) - 3 successes needed',
        difficulty = 'Very Hard',
        enabled = false
    },
    ['pixelhunter'] = {
        name = 'Pixel Hunter',
        description = 'Find 10 glowing pixels in 20x20 grid',
        difficulty = 'Hard',
        enabled = false
    },
    ['snakegame'] = {
        name = 'Snake Game',
        description = 'Classic snake game - collect data packets',
        difficulty = 'Medium',
        enabled = false
    },
    ['circuitbreaker'] = {
        name = 'Circuit Breaker',
        description = 'Break circuit connections in sequence',
        difficulty = 'Medium',
        enabled = false
    },
    ['dashgame'] = {
        name = 'Dash Game',
        description = 'Dash through security barriers',
        difficulty = 'Medium',
        enabled = false
    },
    ['towerofhanoi'] = {
        name = 'Tower of Hanoi',
        description = 'Solve classic Tower of Hanoi puzzle',
        difficulty = 'Hard',
        enabled = false
    },
    ['hashcracker'] = {
        name = 'Hash Cracker',
        description = 'Crack encrypted hash values',
        difficulty = 'Very Hard',
        enabled = false
    },
    ['quickmath'] = {
        name = 'Quick Math',
        description = 'Solve math problems quickly',
        difficulty = 'Medium',
        enabled = false
    },
    ['rotarylock'] = {
        name = 'Rotary Lock',
        description = 'Unlock rotary combination lock',
        difficulty = 'Hard',
        enabled = false
    },
    ['passwordcrack'] = {
        name = 'Password Crack',
        description = 'Crack password combinations',
        difficulty = 'Hard',
        enabled = false
    },
    ['sequencematch'] = {
        name = 'Sequence Match',
        description = 'Match security sequences',
        difficulty = 'Medium',
        enabled = false
    },
    ['keypadcrack'] = {
        name = 'Keypad Crack',
        description = 'Crack keypad entry codes',
        difficulty = 'Medium',
        enabled = false
    },
    ['networktrace'] = {
        name = 'Network Trace',
        description = 'Trace network connections',
        difficulty = 'Hard',
        enabled = false
    }
}

Config.UI = {
    closeKey = 27,
    soundEnabled = true
}

Config.GameCategories = {
    easy = {'mirrorcode', 'clickerrace'},
    medium = {'power', 'firewall', 'memory', 'frequency', 'packet', 'voltage', 'security', 
              'bioscan', 'jam', 'worm', 'fracture', 'magnetic', 
              'patternmemory', 'colorseq', 'numberseq', 'logicgrid',
              'reaction', 'typeracer', 'mazerunner', 'blockstacker', 
              'simonsays', 'memorycards', 'snakegame', 'circuitbreaker', 
              'dashgame', 'quickmath', 'sequencematch', 'keypadcrack'},
    hard = {'quantum', 'neural', 'mathchain', 'symbolmatch', 'pathmemory', 'binarydec',
            'flappybypass', 'lockpick', 'aimtrainer', 'arrowrhythm', 'laserdodge', 'soundmatch', 
            'pixelhunter', 'towerofhanoi', 'rotarylock', 'passwordcrack', 'networktrace'},
    veryhard = {'zeroday', 'cipherwheel', 'stopwatch', 'hashcracker'}
}

