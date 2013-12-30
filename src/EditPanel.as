package
{
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
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
	
	public class EditPanel extends TitleWindow
	{
		private var editTarget:MatSprite;
		private var dots:Array;
		private var line:Shape;
		private var map:Sprite;
		
		private var moveTypeBox:ComboBox;
		private var speedInput:TextInput;
		
		public function EditPanel(target:MatSprite)
		{
			this.editTarget = target;
			dots = new Array;
			this.title = "编辑";
			this.width = 500;
			this.height = 600;
			
			var mapContain:UIComponent = new UIComponent;
			this.addElement(mapContain);
			
			var icon:MatSprite = new MatSprite(target.type, 100);
			icon.x = 70;
			icon.y = 120;
			mapContain.addChild(icon);
			
			var user1:ArrayCollection = new ArrayCollection([
				{label:"默认行为",data:0},
				{label:"定点",data:1},
				{label:"循环",data:2},
				{label:"追踪英雄",data:3},
				{label:"自定义",data:4},
				{label:"追踪当前",data:5}
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
			});
			mapContain.addChild(moveTypeBox);
			
			mapContain.addChild(getLabel("速度：", 20, 180));
			speedInput = new TextInput;
			speedInput.width = 100;
			speedInput.height = 25;
			speedInput.x = 20;
			speedInput.y = 200;
			speedInput.restrict = "0123456789";
			mapContain.addChild(speedInput);
			
			var btn:Button = new Button;
			btn.label = "保存";
			btn.width = 50;
			btn.height = 30;
			btn.x = 45; 
			btn.y = 400;
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
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function getLabel(label:String, px:int, py:int):TextField
		{
			var t:TextField = new TextField;
			t.text = label;
			t.defaultTextFormat = new TextFormat(null, 10);
			t.x = px;
			t.y = py;
			return t;
		}
		
		
		private function onMapClick(e:MouseEvent):void
		{
			var type:int = moveTypeBox.selectedItem.data;
			if(type == 1)
			{
				if(dots.length == 0)
					makeDot(0xff0000, e.localX, e.localY);
			}
			else if(type == 2)
			{
				makeDot(0xff0000, e.localX, e.localY);
			}
			else if(type == 3)
			{
				
			}
			else if(type == 4)
			{
				if(dots.length > 0)
				{
					var px:Number = (e.localX + dots[dots.length-1].x)*0.5;
					var py:Number = (e.localY + dots[dots.length-1].y)*0.5;
					makeDot(0x00ff00, px, py);
				}
				makeDot(0xff0000, e.localX, e.localY);
				render();
			}
			
			
		}
		
		private function makeDot(color:uint, px:int, py:int):Sprite
		{
			var dot:Sprite = new Sprite;
			dot.graphics.beginFill(color);
			dot.graphics.drawCircle(0, 0, 10);
			dot.graphics.endFill();
			dot.addEventListener(MouseEvent.MOUSE_DOWN, onDotMouseDown);
			dot.addEventListener(MouseEvent.MOUSE_MOVE, onDotMove);
			dot.addEventListener(MouseEvent.MOUSE_UP, onDotMouseUp);
			
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("删除");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDelete);
			menu.addItem(item);
			dot.contextMenu = menu;
			
			dot.x = px;
			dot.y = py;
			dots.push(dot);
			map.addChild(dot);
			return dot;
		}
		
		private function onDotMouseDown(event:MouseEvent):void
		{
			event.stopPropagation();
			(event.target as Sprite).startDrag();
		}
		private function onDotMove(event:MouseEvent):void
		{
			if(moveTypeBox.selectedItem.data == 4)
				render();
		}
		
		private function onDotMouseUp(event:MouseEvent):void
		{
			event.stopPropagation();
			(event.target as Sprite).stopDrag();
		}
		
		private function onDelete(event:ContextMenuEvent):void
		{
			var type:int = moveTypeBox.selectedItem.data;
			for(var i:int = 0; i < dots.length; i++)
				if(dots[i] == event.contextMenuOwner)
					if(type == 4)
					{
						var start:int = i%2==0 ? i-1: i;
						if(start>=0)
							map.removeChild(dots[start]);
						map.removeChild(dots[start+1]);
						dots.splice(start, 2);
						render();
						return;
					}
					else
					{
						map.removeChild(dots[i]);
						dots.splice(i, 1);
						return;
					}
		}
		private function onSave(e:MouseEvent):void
		{
			if(speedInput.text.length == 0)
			{
				Alert.show("输入速度");
				return;
			}
			
			var type:int = moveTypeBox.selectedItem.data;
			var route:Array = new Array;
			for(var i:int = 0; i < dots.length; i++)
			{
				var pos:Object = new Object;
				if(type == 4)
				{
					pos.x = dots[i].x - dots[0].x;
					pos.y = dots[i].y - dots[0].y;
				}
				else
				{
					pos.x = dots[i].x;
					pos.y = 480-dots[i].y;
				}
				pos.x *= 2;
				pos.y *= 2;
				route.push(pos);
			}
			
			Data.getInstance().enemyMoveData[editTarget.type] = new Object;
			Data.getInstance().enemyMoveData[editTarget.type]["move_type"] = type;
			Data.getInstance().enemyMoveData[editTarget.type]["move"] = new Object;
			Data.getInstance().enemyMoveData[editTarget.type]["move"].speed = int(speedInput.text);
			if(type == 1)
				Data.getInstance().enemyMoveData[editTarget.type]["move"].dir = route;
			else if(type == 2)
				Data.getInstance().enemyMoveData[editTarget.type]["move"].loops = route;
			else if(type == 4)
				Data.getInstance().enemyMoveData[editTarget.type]["move"].route = route;
			
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