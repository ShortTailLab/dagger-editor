function MAKE_LEVEL(){ var level = {
	"pos": [
		{
			"y": 1100,
			"type": "11000",
			"x": 248.8
		},
		{
			"y": 1200,
			"type": "11000",
			"x": 462.2
		},
		{
			"y": 1700,
			"type": "11000",
			"x": 320
		}
	],
	"defs": {
		"40000": {
			"name": "宝箱",
			"level": 1,
			"attack": 2,
			"move": {},
			"defend": 0,
			"face": "4001",
			"bonus": 7002,
			"move_type": 0,
			"health": 2,
			"rbonus": 8002
		},
		"20000": {
			"name": "BOSS",
			"bullet": {
				"gap": 2.5,
				"id": 50001
			},
			"attack": 3,
			"rbonus": 8004,
			"health": 10,
			"face": "2001",
			"bonus": 7004,
			"move_type": 2,
			"level": 3,
			"move": {
				"speed": 150,
				"loops": [
					[
						100,
						700
					],
					[
						320,
						600
					],
					[
						540,
						700
					]
				]
			},
			"defend": 0
		},
		"50001": {
			"name": "子弹2",
			"level": 1,
			"attack": 2,
			"rbonus": 8004,
			"defend": 0,
			"face": "5002",
			"bonus": 7004,
			"move_type": 4,
			"health": 1,
			"move": {
				"speed": 300
			}
		},
		"50000": {
			"name": "子弹",
			"level": 1,
			"attack": 1,
			"rbonus": 8004,
			"defend": 0,
			"face": "5001",
			"bonus": 7004,
			"move_type": 4,
			"health": 1,
			"move": {
				"speed": 300
			}
		},
		"11000": {
			"name": "枪兵",
			"level": 1,
			"attack": 1,
			"rbonus": 8001,
			"defend": 0,
			"face": "1001",
			"bonus": 7001,
			"move_type": 1,
			"health": 1,
			"move": {
				"speed": 300,
				"dir": [
					0,
					-1
				]
			}
		},
		"13000": {
			"name": "刀盾兵",
			"level": 2,
			"attack": 2,
			"rbonus": 8003,
			"defend": 0,
			"face": "1002",
			"bonus": 7003,
			"move_type": 3,
			"health": 3,
			"move": {
				"speed": 250
			}
		},
		"14000": {
			"name": "弓箭手",
			"bullet": {
				"gap": 4,
				"id": 50000
			},
			"attack": 3,
			"rbonus": 8004,
			"health": 10,
			"face": "1003",
			"bonus": 7004,
			"move_type": 1,
			"level": 3,
			"move": {
				"speed": 300,
				"dir": [
					0,
					-1
				]
			},
			"defend": 0
		}
	}
}; return level; }