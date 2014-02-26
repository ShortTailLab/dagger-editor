function MAKE_LEVEL(){ var level = {
	"trigger": [],
	"behavior": {
		"0101Spear": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.par(BT.Node.MoveDirection(cc.p(0,-1),200),BT.Node.WhenPlayerInRange(150,BT.Node.MeleeAttack(100,0.3,127)));},
		"0101Knife": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.par(BT.Node.WhenPlayerInRange(100,BT.Node.MeleeAttack(100,0.3,204)),BT.sel(BT.Node.WhenYLessThanPlayer(BT.Node.FollowPlayer(220)),BT.Node.MoveDirection(cc.p(0,-1),220)));},
		"StayOnMay": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.Node.StayOnMap();},
		"0101Tower3": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.par(BT.Node.StayOnMap(),BT.Node.EmitDirectBulletByProfile(cc.p(1,-1),0.03,1010109));},
		"0101Tower4": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.par(BT.Node.StayOnMap(),BT.Node.EmitDirectBulletByProfile(cc.p(-1,-1),0.03,1010109));},
		"0101Tower2": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.par(BT.Node.StayOnMap(),BT.Node.EmitDirectBulletByProfile(cc.p(-1,0),0.03,1010109));},
		"0101Tower": function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return BT.par(BT.Node.StayOnMap(),BT.Node.EmitDirectBulletByProfile(cc.p(1,0),0.03,1010109));}
	},
	"trap": {},
	"objects": {
		"139335322505632": {
			"time": 9556,
			"name": "1010101",
			"coord": cc.p(692,9556)
		},
		"139338701527259": {
			"time": 16668,
			"name": "1010106",
			"coord": cc.p(656,16668)
		},
		"139338724852675": {
			"time": 18262,
			"name": "1010102",
			"coord": cc.p(442,18262)
		},
		"139338584956028": {
			"time": 13564,
			"name": "1010102",
			"coord": cc.p(362,13564)
		},
		"139338542502711": {
			"time": 11790,
			"name": "1010102",
			"coord": cc.p(158,11790)
		},
		"139335238548616": {
			"time": 5524,
			"name": "1010101",
			"coord": cc.p(78,5524)
		},
		"139338747577295": {
			"time": 20800,
			"name": "1010102",
			"coord": cc.p(440,20800)
		},
		"139338554797021": {
			"time": 12296,
			"name": "1010102",
			"coord": cc.p(260,12296)
		},
		"139335365416540": {
			"time": 10746,
			"name": "1010101",
			"coord": cc.p(204,10746)
		},
		"139338746157788": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(200,20600)
		},
		"13933519441842": {
			"time": 3410,
			"name": "1010101",
			"coord": cc.p(354,3410)
		},
		"139338581296826": {
			"time": 13180,
			"name": "1010106",
			"coord": cc.p(678,13180)
		},
		"139338705683165": {
			"time": 17200,
			"name": "1010102",
			"coord": cc.p(640,17200)
		},
		"139338726315176": {
			"time": 18424,
			"name": "1010102",
			"coord": cc.p(376,18424)
		},
		"13933852523004": {
			"time": 11404,
			"name": "1010102",
			"coord": cc.p(362,11404)
		},
		"139335307621725": {
			"time": 7800,
			"name": "1010102",
			"coord": cc.p(360,7800)
		},
		"139338694991254": {
			"time": 15710,
			"name": "1010102",
			"coord": cc.p(352,15710)
		},
		"139335323163933": {
			"time": 9504,
			"name": "1010101",
			"coord": cc.p(122,9504)
		},
		"13933522281999": {
			"time": 4552,
			"name": "1010101",
			"coord": cc.p(74,4552)
		},
		"139338742716583": {
			"time": 20200,
			"name": "1010102",
			"coord": cc.p(520,20200)
		},
		"139338545945912": {
			"time": 11878,
			"name": "1010101",
			"coord": cc.p(152,11878)
		},
		"139335239358117": {
			"time": 5532,
			"name": "1010101",
			"coord": cc.p(524,5532)
		},
		"13933046478681": {
			"time": 1608,
			"name": "1010101",
			"coord": cc.p(286,1608)
		},
		"139338692592948": {
			"time": 15400,
			"name": "1010102",
			"coord": cc.p(200,15400)
		},
		"139338556892223": {
			"time": 12590,
			"name": "1010101",
			"coord": cc.p(52,12590)
		},
		"139335365988441": {
			"time": 10794,
			"name": "1010101",
			"coord": cc.p(640,10794)
		},
		"139338681963344": {
			"time": 15062,
			"name": "1010102",
			"coord": cc.p(250,15062)
		},
		"13933519484643": {
			"time": 3418,
			"name": "1010101",
			"coord": cc.p(134,3418)
		},
		"139338692682549": {
			"time": 15396,
			"name": "1010102",
			"coord": cc.p(312,15396)
		},
		"13933852530685": {
			"time": 11402,
			"name": "1010102",
			"coord": cc.p(480,11402)
		},
		"139335310195226": {
			"time": 8044,
			"name": "1010102",
			"coord": cc.p(268,8044)
		},
		"139338720795971": {
			"time": 17800,
			"name": "1010102",
			"coord": cc.p(200,17800)
		},
		"139338706698566": {
			"time": 17290,
			"name": "1010102",
			"coord": cc.p(308,17290)
		},
		"139338557163424": {
			"time": 12622,
			"name": "1010101",
			"coord": cc.p(316,12622)
		},
		"139335331235234": {
			"time": 9908,
			"name": "1010101",
			"coord": cc.p(202,9908)
		},
		"139335224316710": {
			"time": 4582,
			"name": "1010101",
			"coord": cc.p(162,4582)
		},
		"139338729735878": {
			"time": 19200,
			"name": "1010103",
			"coord": cc.p(40,19200)
		},
		"139338697104055": {
			"time": 15850,
			"name": "1010102",
			"coord": cc.p(590,15850)
		},
		"139338747672596": {
			"time": 20800,
			"name": "1010102",
			"coord": cc.p(600,20800)
		},
		"139338546532313": {
			"time": 11922,
			"name": "1010101",
			"coord": cc.p(466,11922)
		},
		"139335240931718": {
			"time": 5768,
			"name": "1010101",
			"coord": cc.p(206,5768)
		},
		"13933510728660": {
			"time": 2210,
			"name": "1010101",
			"coord": cc.p(536,2210)
		},
		"139338746217389": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(280,20600)
		},
		"139338656467629": {
			"time": 13800,
			"name": "1010102",
			"coord": cc.p(360,13800)
		},
		"13934020713430": {
			"time": 1600,
			"name": "1010105",
			"coord": cc.p(440,1600)
		},
		"139335366696442": {
			"time": 10790,
			"name": "1010101",
			"coord": cc.p(480,10790)
		},
		"139338748488597": {
			"time": 21000,
			"name": "1010101",
			"coord": cc.p(200,21000)
		},
		"139338678253840": {
			"time": 14600,
			"name": "1010101",
			"coord": cc.p(40,14600)
		},
		"139338723352772": {
			"time": 18198,
			"name": "1010105",
			"coord": cc.p(42,18198)
		},
		"13933852813166": {
			"time": 11606,
			"name": "1010101",
			"coord": cc.p(80,11606)
		},
		"139335311733627": {
			"time": 8046,
			"name": "1010103",
			"coord": cc.p(690,8046)
		},
		"139338746271790": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(360,20600)
		},
		"139338673484136": {
			"time": 14298,
			"name": "1010101",
			"coord": cc.p(348,14298)
		},
		"139338692787250": {
			"time": 15404,
			"name": "1010102",
			"coord": cc.p(416,15404)
		},
		"139335331854335": {
			"time": 9956,
			"name": "1010101",
			"coord": cc.p(596,9956)
		},
		"139335226359011": {
			"time": 4982,
			"name": "1010101",
			"coord": cc.p(164,4982)
		},
		"139338703353661": {
			"time": 16972,
			"name": "1010102",
			"coord": cc.p(376,16972)
		},
		"139338731906279": {
			"time": 20002,
			"name": "1010107",
			"coord": cc.p(54,20002)
		},
		"139338549504316": {
			"time": 11946,
			"name": "1010102",
			"coord": cc.p(242,11946)
		},
		"139335241889419": {
			"time": 5800,
			"name": "1010101",
			"coord": cc.p(622,5800)
		},
		"139338744291884": {
			"time": 20400,
			"name": "1010102",
			"coord": cc.p(40,20400)
		},
		"139338703259260": {
			"time": 16996,
			"name": "1010102",
			"coord": cc.p(186,16996)
		},
		"139338699358456": {
			"time": 16600,
			"name": "1010102",
			"coord": cc.p(520,16600)
		},
		"139335367818944": {
			"time": 10830,
			"name": "1010102",
			"coord": cc.p(536,10830)
		},
		"139338671911434": {
			"time": 14074,
			"name": "1010102",
			"coord": cc.p(360,14074)
		},
		"13933520478164": {
			"time": 3714,
			"name": "1010101",
			"coord": cc.p(268,3714)
		},
		"139338682365745": {
			"time": 15036,
			"name": "1010102",
			"coord": cc.p(614,15036)
		},
		"139338676001037": {
			"time": 14400,
			"name": "1010102",
			"coord": cc.p(40,14400)
		},
		"139335314528128": {
			"time": 8508,
			"name": "1010102",
			"coord": cc.p(196,8508)
		},
		"139338557237825": {
			"time": 12638,
			"name": "1010101",
			"coord": cc.p(440,12638)
		},
		"139338746594191": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(440,20600)
		},
		"139338744442985": {
			"time": 20400,
			"name": "1010102",
			"coord": cc.p(200,20400)
		},
		"13933852830687": {
			"time": 11610,
			"name": "1010101",
			"coord": cc.p(326,11610)
		},
		"139335336200736": {
			"time": 10380,
			"name": "1010105",
			"coord": cc.p(368,10380)
		},
		"139335227220612": {
			"time": 5024,
			"name": "1010101",
			"coord": cc.p(68,5024)
		},
		"139338708273767": {
			"time": 17462,
			"name": "1010102",
			"coord": cc.p(590,17462)
		},
		"139338724714373": {
			"time": 18260,
			"name": "1010102",
			"coord": cc.p(206,18260)
		},
		"139338551057117": {
			"time": 12056,
			"name": "1010101",
			"coord": cc.p(330,12056)
		},
		"139335242488520": {
			"time": 5862,
			"name": "1010101",
			"coord": cc.p(376,5862)
		},
		"139338694364151": {
			"time": 15600,
			"name": "1010102",
			"coord": cc.p(446,15600)
		},
		"139338703414462": {
			"time": 16984,
			"name": "1010102",
			"coord": cc.p(280,16984)
		},
		"13933852060680": {
			"time": 11038,
			"name": "1010102",
			"coord": cc.p(434,11038)
		},
		"139338656593130": {
			"time": 13800,
			"name": "1010102",
			"coord": cc.p(280,13800)
		},
		"13933520710155": {
			"time": 3916,
			"name": "1010101",
			"coord": cc.p(604,3916)
		},
		"13933852855728": {
			"time": 11596,
			"name": "1010101",
			"coord": cc.p(480,11596)
		},
		"139335316400029": {
			"time": 8782,
			"name": "1010102",
			"coord": cc.p(400,8782)
		},
		"139338732111880": {
			"time": 19564,
			"name": "1010108",
			"coord": cc.p(686,19564)
		},
		"139338746666992": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(520,20600)
		},
		"13933510740301": {
			"time": 2402,
			"name": "1010101",
			"coord": cc.p(132,2402)
		},
		"139338676065838": {
			"time": 14400,
			"name": "1010102",
			"coord": cc.p(120,14400)
		},
		"139338709865668": {
			"time": 17200,
			"name": "1010105",
			"coord": cc.p(48,17200)
		},
		"139335362206137": {
			"time": 10450,
			"name": "1010101",
			"coord": cc.p(314,10450)
		},
		"139335229160613": {
			"time": 5272,
			"name": "1010101",
			"coord": cc.p(602,5272)
		},
		"139338658113932": {
			"time": 13888,
			"name": "1010103",
			"coord": cc.p(42,13888)
		},
		"139338748759799": {
			"time": 21014,
			"name": "1010101",
			"coord": cc.p(408,21014)
		},
		"139338699453657": {
			"time": 16616,
			"name": "1010102",
			"coord": cc.p(200,16616)
		},
		"139338551895418": {
			"time": 12054,
			"name": "1010101",
			"coord": cc.p(450,12054)
		},
		"139338683542546": {
			"time": 15060,
			"name": "1010107",
			"coord": cc.p(356,15060)
		},
		"139335245154921": {
			"time": 6376,
			"name": "1010102",
			"coord": cc.p(504,6376)
		},
		"139338678361841": {
			"time": 14654,
			"name": "1010101",
			"coord": cc.p(214,14654)
		},
		"139338724788774": {
			"time": 18262,
			"name": "1010102",
			"coord": cc.p(322,18262)
		},
		"13933852219971": {
			"time": 11110,
			"name": "1010101",
			"coord": cc.p(210,11110)
		},
		"13933520800966": {
			"time": 3998,
			"name": "1010101",
			"coord": cc.p(404,3998)
		},
		"139338705455263": {
			"time": 17200,
			"name": "1010102",
			"coord": cc.p(440,17200)
		},
		"139338748700598": {
			"time": 21006,
			"name": "1010101",
			"coord": cc.p(310,21006)
		},
		"13933852980769": {
			"time": 11470,
			"name": "1010106",
			"coord": cc.p(360,11470)
		},
		"139335318211230": {
			"time": 9090,
			"name": "1010102",
			"coord": cc.p(242,9090)
		},
		"139338673094635": {
			"time": 14260,
			"name": "1010101",
			"coord": cc.p(120,14260)
		},
		"139338678440142": {
			"time": 14682,
			"name": "1010101",
			"coord": cc.p(344,14682)
		},
		"139338742567081": {
			"time": 20200,
			"name": "1010102",
			"coord": cc.p(200,20200)
		},
		"139335362768538": {
			"time": 10438,
			"name": "1010101",
			"coord": cc.p(604,10438)
		},
		"139335230323014": {
			"time": 5352,
			"name": "1010101",
			"coord": cc.p(376,5352)
		},
		"139338746746993": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(600,20600)
		},
		"139338676131439": {
			"time": 14400,
			"name": "1010102",
			"coord": cc.p(200,14400)
		},
		"13933519131160": {
			"time": 3000,
			"name": "1010101",
			"coord": cc.p(280,3000)
		},
		"139338700837658": {
			"time": 16794,
			"name": "1010102",
			"coord": cc.p(424,16794)
		},
		"139338553086619": {
			"time": 12102,
			"name": "1010101",
			"coord": cc.p(654,12102)
		},
		"139335295415423": {
			"time": 6902,
			"name": "1010102",
			"coord": cc.p(282,6902)
		},
		"1393387562388101": {
			"time": 19000,
			"name": "1010104",
			"coord": cc.p(600,19000)
		},
		"139338710995969": {
			"time": 17642,
			"name": "1010102",
			"coord": cc.p(320,17642)
		},
		"139338690764947": {
			"time": 15192,
			"name": "1010102",
			"coord": cc.p(480,15192)
		},
		"139338744574186": {
			"time": 20400,
			"name": "1010102",
			"coord": cc.p(360,20400)
		},
		"13933852227172": {
			"time": 11130,
			"name": "1010101",
			"coord": cc.p(326,11130)
		},
		"13933521678477": {
			"time": 4386,
			"name": "1010103",
			"coord": cc.p(44,4386)
		},
		"139338694463352": {
			"time": 15600,
			"name": "1010102",
			"coord": cc.p(548,15600)
		},
		"139338746082187": {
			"time": 20600,
			"name": "1010102",
			"coord": cc.p(120,20600)
		},
		"139338542273910": {
			"time": 11734,
			"name": "1010102",
			"coord": cc.p(296,11734)
		},
		"139335321667131": {
			"time": 9544,
			"name": "1010101",
			"coord": cc.p(364,9544)
		},
		"139338656694731": {
			"time": 13800,
			"name": "1010102",
			"coord": cc.p(440,13800)
		},
		"139338554865022": {
			"time": 12294,
			"name": "1010102",
			"coord": cc.p(398,12294)
		},
		"139338705621664": {
			"time": 17202,
			"name": "1010102",
			"coord": cc.p(544,17202)
		},
		"139335363258839": {
			"time": 10414,
			"name": "1010101",
			"coord": cc.p(120,10414)
		},
		"139338583052827": {
			"time": 13346,
			"name": "1010102",
			"coord": cc.p(484,13346)
		},
		"139338747498194": {
			"time": 20800,
			"name": "1010102",
			"coord": cc.p(280,20800)
		},
		"139338694651253": {
			"time": 15600,
			"name": "1010102",
			"coord": cc.p(640,15600)
		},
		"13934020720861": {
			"time": 1400,
			"name": "1010105",
			"coord": cc.p(200,1400)
		},
		"139338554717820": {
			"time": 12286,
			"name": "1010102",
			"coord": cc.p(122,12286)
		},
		"139335237244615": {
			"time": 5374,
			"name": "1010101",
			"coord": cc.p(248,5374)
		},
		"13933519148651": {
			"time": 3000,
			"name": "1010101",
			"coord": cc.p(520,3000)
		},
		"139338659850733": {
			"time": 13980,
			"name": "1010105",
			"coord": cc.p(38,13980)
		},
		"139338712573570": {
			"time": 17660,
			"name": "1010106",
			"coord": cc.p(674,17660)
		},
		"13933852467873": {
			"time": 11406,
			"name": "1010102",
			"coord": cc.p(250,11406)
		},
		"139335307400924": {
			"time": 7808,
			"name": "1010102",
			"coord": cc.p(162,7808)
		},
		"13933522121918": {
			"time": 4530,
			"name": "1010101",
			"coord": cc.p(592,4530)
		},
		"139338681652943": {
			"time": 14988,
			"name": "1010102",
			"coord": cc.p(364,14988)
		},
		"139338742647782": {
			"time": 20200,
			"name": "1010102",
			"coord": cc.p(360,20200)
		},
		"1393387488509100": {
			"time": 21040,
			"name": "1010101",
			"coord": cc.p(512,21040)
		}
	},
	"actor": {
		"1010101": {
			"m_defense": 0,
			"health": 204,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾枪兵",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "20000",
			"monster_id": "1010101",
			"behaviors": [
				"0101Spear"
			],
			"p_attack": 127
		},
		"1010102": {
			"m_defense": 0,
			"health": 510,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾刀兵",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "20001",
			"monster_id": "1010102",
			"behaviors": [
				"0101Knife"
			],
			"p_attack": 254
		},
		"1010103": {
			"m_defense": 0,
			"health": 204,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾僵尸（宝箱怪1）",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "20003",
			"monster_id": "1010103",
			"behaviors": [
				"StayOnMay"
			],
			"p_attack": 127
		},
		"1010104": {
			"m_defense": 0,
			"health": 204,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾力士（宝箱怪2）",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "20006",
			"monster_id": "1010104",
			"behaviors": [
				"StayOnMay"
			],
			"p_attack": 127
		},
		"1010105": {
			"m_defense": 0,
			"health": 1020,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾箭手（Left）",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "20002",
			"monster_id": "1010105",
			"behaviors": [
				"0101Tower"
			],
			"p_attack": 254
		},
		"1010106": {
			"m_defense": 0,
			"health": 1020,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾箭手（Right）",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "40000",
			"monster_id": "1010106",
			"behaviors": [
				"0101Tower2"
			],
			"p_attack": 254
		},
		"1010107": {
			"m_defense": 0,
			"health": 1020,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾箭手（LeftUp）",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "30000",
			"monster_id": "1010107",
			"behaviors": [
				"0101Tower3"
			],
			"p_attack": 254
		},
		"1010108": {
			"m_defense": 0,
			"health": 1020,
			"triggers": [],
			"m_attack": 0,
			"monster_name": "黄巾箭手（RightDown）",
			"size": cc.size(40,80),
			"p_defense": 0,
			"monster_type": "Monster",
			"face": "30001",
			"monster_id": "1010108",
			"behaviors": [
				"0101Tower4"
			],
			"p_attack": 254
		}
	},
	"luck": {},
	"map": {
		"speed": 100
	},
	"bullet": {
		"1010109": {
			"offset": "[0,0]",
			"range": "1000",
			"speed": "1000",
			"size": cc.size(2,2),
			"monster_type": "Bullet",
			"face": "10000",
			"m_attack": 0,
			"monster_id": "1010109",
			"monster_name": "激光箭",
			"p_attack": 1
		}
	}
}; return level; }