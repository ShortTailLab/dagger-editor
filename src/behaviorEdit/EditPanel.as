package behaviorEdit
{
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.ComboBox;
	import spark.components.TextInput;
	import spark.components.TitleWindow;
	
	import editEntity.EditBase;
	import editEntity.MatSprite;
	
	public class EditPanel extends TitleWindow
	{
		private var editTarget:MatSprite;
		private var dots:Array;
		private var line:Shape;
		private var map:Sprite;
		
		private var moveTypeBox:ComboBox;
		private var speedInput:TextInput;

		private var attackTypeBox:ComboBox;
		private var intervalInput:TextInput;
		private var radiusInput:TextInput;
		private var attackDamageInput:TextInput;
		private var attackBullet:TextInput;
		private var typeBox:ComboBox;
		
		private var dirXInput:TextInput;
		private var dirYInput:TextInput;
		
		private var actions:ActionsCenter;
		
		public function EditPanel(target:MatSprite)
		{
			this.editTarget = target;
			actions = new ActionsCenter(this);
			dots = new Array;
			this.title = "编辑";
			this.width = 500;
			this.height = 600;    
			
			var mapContain:UIComponent = new UIComponent;
			this.addElement(mapContain);
			
			var icon:EditBase = new MatSprite(null, target.type, 100);
			icon.x = 70;
			icon.y = 110;
			mapContain.addChild(icon);
			
			var matType:ArrayCollection = new ArrayCollection([
				{label:"enemy",data:0},
				{label:"player",data:1},
				{label:"neutral",data:2}
			]);
			
			var user1:ArrayCollection = new ArrayCollection([
				{label:"默认",data:"Default"},
				{label:"直线",data:"MoveDirectionAndAttack"},
				{label:"路径停止",data:"CustomPathStopAtExit"},
				{label:"路径自动",data:"CustomPathTangentExit"},
				{label:"追踪行走",data:"ChaseAndAttack"},
				{label:"非行走",data:"StayOnMap"},
				{label:"巡逻行走",data:"MoveLoopAndAttack"}
			]); 
			
			var atkData:ArrayCollection = new ArrayCollection([
				{label:"",data:0},
				{label:"M",data:1},
				{label:"R",data:2}
			]); 
			
			mapContain.addChild(getLabel("行动方式:", 20, 130));
			moveTypeBox = new ComboBox();
			moveTypeBox.width = 100;
			moveTypeBox.x = 20;
			moveTypeBox.y = 150;
			moveTypeBox.dataProvider = user1;
			moveTypeBox.selectedIndex = 0;
			moveTypeBox.addEventListener(Event.CHANGE, function(){
				line.graphics.clear();
				while(dots.length > 0)
					map.removeChild(dots.pop());
				actions.setCurrId(moveTypeBox.selectedItem.data);
				dirXInput.visible = dirYInput.visible = (moveTypeBox.selectedItem.data == MoveType.LineWalk);
			});
			mapContain.addChild(moveTypeBox);
			
			mapContain.addChild(getLabel("速度：", 20, 175));
			speedInput = new TextInput;
			speedInput.width = 100;
			speedInput.height = 25;
			speedInput.x = 20;
			speedInput.y = 190;
			mapContain.addChild(speedInput);
			
			mapContain.addChild(getLabel("dir:", 20, 215));
			dirXInput = new TextInput;
			dirXInput.width = 50;
			dirXInput.height = 25;
			dirXInput.x = 20;
			dirXInput.y = 230;
			mapContain.addChild(dirXInput);
			dirYInput = new TextInput;
			dirYInput.width = 50;
			dirYInput.height = 25;
			dirYInput.x = 80;
			dirYInput.y = 230;
			dirYInput.restrict = "-.0123456789";
			mapContain.addChild(dirYInput);
			
			mapContain.addChild(getLabel("攻击方式:", 20, 265));
			attackTypeBox = new ComboBox();
			attackTypeBox.width = 100;
			attackTypeBox.x = 20;
			attackTypeBox.y = 280;
			attackTypeBox.dataProvider = atkData;
			attackTypeBox.selectedIndex = 0;
			attackTypeBox.addEventListener(Event.CHANGE, function(){
				attackBullet.visible = attackTypeBox.selectedItem.data == 2;
			});
			mapContain.addChild(attackTypeBox);
			
			mapContain.addChild(getLabel("间隔(interval):", 20, 305));
			intervalInput = new TextInput;
			intervalInput.width = 100;
			intervalInput.height = 25;
			intervalInput.x = 20;
			intervalInput.y = 320;
			mapContain.addChild(intervalInput);
			mapContain.addChild(getLabel("攻击半径(radius):", 20, 345));
			radiusInput = new TextInput;
			radiusInput.width = 100;
			radiusInput.height = 25;
			radiusInput.x = 20;
			radiusInput.y = 360;
			mapContain.addChild(radiusInput);
			mapContain.addChild(getLabel("伤害(damage):", 20, 385));
			attackDamageInput = new TextInput;
			attackDamageInput.width = 100;
			attackDamageInput.height = 25;
			attackDamageInput.x = 20;
			attackDamageInput.y = 400;
			mapContain.addChild(attackDamageInput);
			mapContain.addChild(getLabel("子弹类型(bullet):", 20, 425));
			attackBullet = new TextInput;
			attackBullet.width = 100;
			attackBullet.height = 25;
			attackBullet.x = 20;
			attackBullet.y = 440;
			mapContain.addChild(attackBullet);
			
			mapContain.addChild(getLabel("类型:", 20, 465));
			typeBox = new ComboBox();
			typeBox.width = 100;
			typeBox.x = 20;
			typeBox.y = 480;
			typeBox.dataProvider = matType;
			typeBox.selectedIndex = 0;
			typeBox.addEventListener(Event.CHANGE, function(){
				
			});
			mapContain.addChild(typeBox);
			
			var btn:Button = new Button;
			btn.label = "保存";
			btn.width = 50;
			btn.height = 30;
			btn.x = 45; 
			btn.y = 520;
			btn.addEventListener(MouseEvent.CLICK, onSave);
			mapContain.addChild(btn);

			map = new Sprite;
			map.graphics.lineStyle(1, 0x000000);
			map.graphics.beginFill(0xffffff);
			map.graphics.drawRect(0, 0, 320, 480);
			map.graphics.endFill();
			
			map.x = 150;
			map.y = 20;
			map.addEventListener(MouseEvent.MOUSE_UP, onMapClick);
			mapContain.addChild(map);
			
			line = new Shape;
			map.addChild(line);
			
			initActions();
			this.addEventListener(CloseEvent.CLOSE, onClose);
			
			if(Data.getInstance().enemyEditData.hasOwnProperty(target.type))
			{
				var data:Object = Data.getInstance().enemyEditData[target.type];
				if(data.hasOwnProperty("move_type"))
				{
					var moveType:String = data["move_type"];
					for(var i:int = 0;  i < user1.length; i++)
						if(user1[i].data == moveType)
						{
							moveTypeBox.selectedIndex = i;
							break;
						}
					actions.setCurrId(moveTypeBox.selectedItem.data);
					if(data.hasOwnProperty("move_args"))
					{
						speedInput.text = Data.getInstance().enemyEditData[target.type]["move_args"]["speed"];
						var recordDots:Array = null;
						if(moveType == MoveType.Wander && data["move_args"].hasOwnProperty("loop"))
							recordDots = Data.getInstance().enemyEditData[target.type]["move_args"].loop;
						else if((moveType == MoveType.CurveWalk || moveType == MoveType.CurveAndOut) && data["move_args"].hasOwnProperty("route"))
						{
							var route:Array = data["move_args"].route;
							for(var i:int = 0; i < route.length; i++)
							{
								var color:uint = i%2==0 ? 0xff0000 : 0x00ff00;
								var pos:Array = route[i] as Array;
								makeDot(color, pos[0]*0.5, 480-pos[1]*0.5);
							}
							render();
						}
						if(moveType == MoveType.LineWalk)
						{
							var pos:Array = Data.getInstance().enemyEditData[target.type]["move_args"].dir as Array;
							dirXInput.text = pos[0];
							dirYInput.text = pos[1];
						}
						if(recordDots)
							for(var d in recordDots)
							{
								var pos:Array = recordDots[d] as Array;
								addDot(pos[0]*0.5, 480-pos[1]*0.5);
							}
					}
					
				}
				
				if(data.hasOwnProperty("attack_type"))
				{
					for(var i:int = 0;  i < atkData.length; i++)
						if(atkData[i].label == data["attack_type"])
						{
							attackTypeBox.selectedIndex = i;
							break;
						}
					attackBullet.visible = data["attack_type"] == "R";
				}
				
				if(data.hasOwnProperty("attack_args"))
				{
					if(data["attack_args"].hasOwnProperty("radius"))
						radiusInput.text = data["attack_args"].radius;
					if(data["attack_args"].hasOwnProperty("interval"))
						intervalInput.text = data["attack_args"].interval;
					attackDamageInput.text = data["attack_args"].damage;
					if(data["attack_args"].hasOwnProperty("bullet"))
						attackBullet.text = data["attack_args"].bullet;
				}
				
				if(data.hasOwnProperty("type"))
				{
					typeBox.selectedIndex = data["typeIndex"];
				}
			}
		}
		
		
		private function initActions():void
		{
			
			/*actions.register("addDots", "1", function(px:int, py:int):void{
				if(this.dots.length == 0)
					this.makeDot(0xff0000, px, py);
			});*/
			
			actions.register("addDots", String(MoveType.Wander), function(px:int, py:int):void{
					this.makeDot(0xff0000, px, py);
			});
			
			
			actions.register("addDots", String(MoveType.CurveWalk), function(px:int, py:int):void{
				if(this.dots.length > 0)
				{
					var px1:Number = (px + this.dots[dots.length-1].x)*0.5;
					var py1:Number = (py + this.dots[dots.length-1].y)*0.5;
					this.makeDot(0x00ff00, px1, py1);
				}
				this.makeDot(0xff0000, px, py);
				this.render();
			});
			
			actions.register("addDots", String(MoveType.CurveAndOut), function(px:int, py:int):void{
				if(this.dots.length > 0)
				{
					var px1:Number = (px + this.dots[dots.length-1].x)*0.5;
					var py1:Number = (py + this.dots[dots.length-1].y)*0.5;
					this.makeDot(0x00ff00, px1, py1);
				}
				this.makeDot(0xff0000, px, py);
				this.render();
			});
		}
		
		private function getLabel(label:String, px:int = 0, py:int=0, size:int = 10):TextField
		{
			var t:TextField = new TextField;
			t.defaultTextFormat = new TextFormat(null, size);
			t.text = label;
			t.x = px;
			t.y = py;
			return t;
		}
		
		
		private function onMapClick(e:MouseEvent):void
		{
			addDot(e.localX, e.localY)
		}
		
		private function addDot(px:int, py:int):void
		{
			actions.exec("addDots", px, py);
		}
		
		private function makeDot(color:uint, px:int, py:int):Sprite
		{
			var dot:Dot = new Dot(color);
			dot.addEventListener(MouseEvent.MOUSE_DOWN, onDotMouseDown);
			dot.addEventListener(MouseEvent.MOUSE_MOVE, onDotMove);
			dot.addEventListener(MouseEvent.MOUSE_UP, onDotMouseUp);
			
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("删除");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDelete);
			menu.addItem(item);
			dot.contextMenu = menu;
			
			dot.setNum(dots.length);
			dot.x = px;
			dot.y = py;
			dots.push(dot);
			map.addChild(dot);
			return dot;
		}
		
		private function orderDots():void
		{
			for(var i:int; i < dots.length; i++)
			{
				Dot(dots[i]).setNum(i);
			}
		}
		
		private function onDotMouseDown(event:MouseEvent):void
		{
			event.stopPropagation();
			(event.currentTarget as Sprite).startDrag();
		}
		private function onDotMove(event:MouseEvent):void
		{
			if(moveTypeBox.selectedItem.data == MoveType.CurveWalk || moveTypeBox.selectedItem.data == MoveType.CurveAndOut)
				render();
		}
		
		private function onDotMouseUp(event:MouseEvent):void
		{
			event.stopPropagation();
			(event.currentTarget as Sprite).stopDrag();
		}
		
		private function onDelete(event:ContextMenuEvent):void
		{
			var type:String = moveTypeBox.selectedItem.data;
			for(var i:int = 0; i < dots.length; i++)
				if(dots[i] == event.contextMenuOwner)
					if(type == MoveType.CurveWalk || type == MoveType.CurveAndOut)
					{
						var relatDotIndex:int = (i==0 || i%2 == 1) ? i : i-1;
						map.removeChild(dots[relatDotIndex]);
						map.removeChild(dots[relatDotIndex+1]);
						dots.splice(relatDotIndex, 2);
						render();
						break;
					}
					else
					{
						map.removeChild(dots[i]);
						dots.splice(i, 1);
						break;
					}
			orderDots();
		}
		private function onSave(e:MouseEvent):void
		{
			if(speedInput.text.length == 0)
			{
				Alert.show("输入速度");
				return;
			}
			
			var type:String = moveTypeBox.selectedItem.data;
			var route:Array = new Array;
			for(var i:int = 0; i < dots.length; i++)
			{
				var pos:Array = new Array;
				pos.push((dots[i].x*2));
				pos.push((480-dots[i].y)*2);
				
				route.push(pos);
			}
			
			if(!Data.getInstance().enemyEditData.hasOwnProperty(editTarget.type))
				Data.getInstance().enemyEditData[editTarget.type] = new Object;
			var enemyData:Object = Data.getInstance().enemyEditData[editTarget.type];
			if(type == MoveType.Default && enemyData.hasOwnProperty("move_type"))
			{
				delete enemyData["move_type"];
				delete enemyData["move_args"];
			}
			else
			{
				enemyData["move_type"] = type;
				enemyData["move_args"] = new Object;
				enemyData["move_args"].speed = int(speedInput.text);
				if(type == MoveType.Wander)
					enemyData["move_args"].loop = route;
				else if(type == MoveType.CurveWalk || type == MoveType.CurveAndOut)
				{
					enemyData["move_args"].route = route;
				}
				else if(type == MoveType.LineWalk)
				{
					var pos:Array = new Array;
					pos.push(dirXInput.text.length>0?Number(dirXInput.text):0);
					pos.push(dirYInput.text.length>0?Number(dirYInput.text):0);
					enemyData["move_args"].dir = pos;
				}
			}
				
			var atkType:int = attackTypeBox.selectedItem.data;
			if(atkType == 0 && enemyData.hasOwnProperty("attack_type"))
			{
				delete enemyData["attack_type"];
				delete enemyData["attack_args"];
			}
			else
			{
				Data.getInstance().enemyEditData[editTarget.type]["attack_type"] = attackTypeBox.selectedItem.label;
				Data.getInstance().enemyEditData[editTarget.type]["attack_args"] = new Object;
				if(intervalInput.text.length > 0)
					Data.getInstance().enemyEditData[editTarget.type]["attack_args"].interval = intervalInput.text;
				if(radiusInput.text.length >= 0)
					Data.getInstance().enemyEditData[editTarget.type]["attack_args"].radius = radiusInput.text;
				if(attackDamageInput.text.length > 0)
					Data.getInstance().enemyEditData[editTarget.type]["attack_args"].damage = attackDamageInput.text;
				if(attackBullet.text.length > 0)
					Data.getInstance().enemyEditData[editTarget.type]["attack_args"].bullet = attackBullet.text;
			}
			
			enemyData["type"] = typeBox.selectedItem.label;
			enemyData["typeIndex"] = typeBox.selectedIndex;
				
			Data.getInstance().saveEnemyData();
			Alert.show("保存成功");
		}
		
		private function render():void
		{
			if(dots.length > 0)
			{
				line.graphics.clear();
				line.graphics.lineStyle(1);
				line.graphics.moveTo(dots[0].x, dots[0].y);
				for(var i:int = 2; i < dots.length; )
				{
					line.graphics.curveTo(dots[i-1].x, dots[i-1].y, dots[i].x, dots[i].y);
					i+=2;
				}
			}
		}
		
		private function onClose(e:CloseEvent):void
		{
			PopUpManager.removePopUp(this);
		}
	}
}

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Dictionary;


class Dot extends Sprite
{
	private var label:TextField;
	
	public function Dot(color:uint)
	{
		graphics.beginFill(color);
		graphics.drawCircle(0, 0, 10);
		graphics.endFill();
		
		label = new TextField;
		label.defaultTextFormat = new TextFormat(null, 20);
		label.selectable = false;
		label.width = label.height = 20;
		
		addChild(label);
	}
	
	public function setNum(num:int):void
	{
		label.text = String(num);
		label.x = -label.textWidth*0.5;
		label.y = -label.textHeight*0.5;
	}
}

class ActionsCenter
{
	private var actions:Dictionary;
	private var currId:String;
	private var target:*;
	
	public function ActionsCenter(_target:*)
	{
		target = _target;
		actions = new Dictionary;
		currId = "";
	}
	
	public function setCurrId(id:String):void
	{
		currId = id;
	}
	
	public function register(funcName:String, id:String, func:Function):void
	{
		if(!actions.hasOwnProperty(funcName))
			actions[funcName] = new Dictionary;
		actions[funcName][id] = func;
	}
	
	public function unRegisterFunc(funcName:String):void
	{
		if(actions.hasOwnProperty(funcName))
			delete actions[funcName];
	}
	
	public function unRegisterId(id:String):void
	{
		for each(var a:Dictionary in actions)
			if(a.hasOwnProperty(id))
				delete a[id];
	}
	
	public function exec(funcName:String, ...rest):void
	{
		if(actions.hasOwnProperty(funcName) && currId.length > 0 && actions[funcName].hasOwnProperty(currId))
		{
			var func:Function = actions[funcName][currId] as Function;
			func.apply(target, rest);
		}
			
	}
}

class MoveType
{
	static public var Default:String = "Default"
	static public var LineWalk:String = "MoveDirectionAndAttack";
	static public var CurveWalk:String = "CustomPathStopAtExit";
	static public var StalkWalk:String = "ChaseAndAttack";
	static public var STATIC:String = "StayOnMap"
	static public var Wander:String = "MoveLoopAndAttack";
	static public var CurveAndOut:String = "CustomPathTangentExit"
}


