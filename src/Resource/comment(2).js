/*
    // [*] means optional field

    "actor"     // actor's definitions
    {
        "name" : string     // identifier of actor, should be unique
        {
            "face" : string     // prefix of resource
            "health" & "attack" and so on ..
            "behaviors" : [
                function () { return ... },
                function () { return ... },
                
            ]
            "actions" : 
            [
                {
                    "type" : string // one of { "StayOnMap", "MoveDirection",
                                    // "MoveLoop", "Chase",
                                    // "CustemPathTangentExit", "CustomPathStopAtExit",
                                    // "MeleeAttack", "RangedAttack" ,"DIY" }
                                    // "DIY" is reserved for behaviors created by designer

                    1. [*]  //"StayOnMap"

                    2. [*]  // "MoveDirection"
                    "speed" : float     // move speed
                    "dir"   : [x, y]    // for directional movement

                    3. [*]  // "MoveLoop"
                    "speed" : float
                    "loop"  : array of [x, y]

                    4. [*]  // "Chase"
                    "speed" : float

                    5. [*]  // "CustomPathStopAtExit"
                    "speed" : float
                    "route" : array of [x, y]

                    6. [*]  // "CustomPathTangentExit"
                    "speed" : float
                    "route" : array of [x, y]
                    
                    1. [*] // "MeleeAttack"
                    "damage"    : float     // direct damage that attack causes
                    "interval"  : float     // attack interval
                    "radius"    : float     // guard range

                    2. [*] // "RangedAttack"
                    "bullet"    : string    // name of the corresponding bullet
                    "interval"  : float     //
                    "radius"    : float     //
                    "damage"    : float 

                    3. [*] // "DIY" --  [TODO]  --
                }
            ]
        }
    }

    "trap"  // trap's definitions
    {
        "name" : 
        {
            "type" : string // "RollingStone/Meteorite/...", see enemy.js's Trap

            1. [*] // RollingStone
            "speed" : float
            "dps"   : float // damage per second

            2. [*] // Meteorite
            "damage"     : float     // one-time injury
            "firing_dps" : float    // continoues injury

            3. [*] // Bangalore
            "size"  : [width, heigh]    // size of effective area
        }
    }

    "objects"
    [
        {
            "id"    : string    // unique identifier
            "name"  : string    // who, the type of name's owner 
                                // should be "trap" or "actor"
            "coord" : [x, y]    // where, based on screen coordinate system
        }
    ]

    "trigger"   // things would be parsed & created during gameplay
    [
        {
            "cond" : 
            {
                "type"  :   string                  // "Time"|"Area"|"OnDeath"

                1. [*] // "Time"
                "time"  : float                     // when trigger happens

                2. [*] // "Area"
                "area"  : [x, y, width, height]     // based on map coordinate system,
                                                    // rect of effective area

                3. [*] // "OnDeath"
                "target" : string                   // the instance's identifier of objects 
            }

            "result" :
            {
                "type" : string                     // "Object" | "Success" |

                1. [*] // Object
                "objs"  :                           // reference to items of "objects"
                [
                    "id" : string                   // 
                ]

                2. [*] "Success"
            }
        }
    ]
*/
    
