{

	"BT.Node.Tags" : [
		{ "name":"tags", "type":"array_string" },
		{ "name":"first", "type":"node" },
	],
	"BT.Node.Destroy" : [
		{ "name":"time", "type":"float" },
	],
	"BT.Node.Die" : [
		{ "name":"time", "type":"float" },
	],
	"BT.Node.UnderAttack" : [
	],
	"BT.Node.WhenPlayerInRange" : [
		{ "name":"radius", "type":"float" },
		{ "name":"first", "type":"node" },
	],
	"BT.Node.WhenEnemyInRange" : [
		{ "name":"radius", "type":"float" },
		{ "name":"first", "type":"node" },
	],
	"BT.Node.WhenPlayerHealthRateLessThan" : [
		{ "name":"rate", "type":"float" },
		{ "name":"first", "type":"node" },
	],
	"BT.Node.WhenTargetHealthRateLessThan" : [
		{ "name":"target", "type":"int" },
		{ "name":"rate", "type":"float" },
		{ "name":"first", "type":"node" },
	],
	"BT.Node.MeleeAttack" : [
		{ "name":"radius", "type":"float" },
		{ "name":"interval", "type":"float" },
		{ "name":"damage", "type":"float" },
	],
	"BT.Node.RangeAttackByCreator" : [
		{ "name":"interval", "type":"float" },
	],
	"BT.Node.ContinuousAttack" : [
		{ "name":"size", "type":"ccsize" },
		{ "name":"dps", "type":"float" },
	],
	"BT.Node.RangeAttackByProfile" : [
		{ "name":"interval", "type":"float" },
		{ "name":"addr", "type":"string" },
	],
	"BT.Node.MoveDirection" : [
		{ "name":"dir", "type":"ccp" },
		{ "name":"speed", "type":"float" },
	],
	"BT.Node.StayOnMap" : [
	],
	"BT.Node.ChasePlayer" : [
		{ "name":"speed", "type":"float" },
		{ "name":"accel", "type":"float" },
	],
	"BT.Node.MoveAlongPath" : [
		{ "name":"path", "type":"array_ccp" },
		{ "name":"speed", "type":"float" },
	],
	"BT.Node.MoveAlongPathInCurve" : [
		{ "name":"path", "type":"array_ccp" },
		{ "name":"speed", "type":"float" },
	],
	"BT.Node.ControlledByMouse" : [
		{ "name":"speed", "type":"float" },
	],
	"BT.Node.Follow" : [
		{ "name":"tid", "type":"int" },
		{ "name":"speed", "type":"float" },
		{ "name":"offset", "type":"ccp" },
		{ "name":"rotate", "type":"bool" },
	],
	"BT.Node.MoveAndAttackLoop" : [
		{ "name":"path", "type":"array_ccp" },
		{ "name":"speed", "type":"float" },
		{ "name":"interval", "type":"float" },
		{ "name":"dir", "type":"ccp" },
		{ "name":"bullet", "type":"string" },
	],

}
