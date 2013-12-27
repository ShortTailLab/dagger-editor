package
{
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	
	public class EditPanel extends TitleWindow
	{
		private var editTargets:Array;
		private var dots:Array;
		private var line:Shape;
		var map:Sprite;
		
		public function EditPanel(target:Array)
		{
			this.editTargets = target;
			dots = new Array;
			this.title = "编辑";
			this.width = 500;
			this.height = 600;
			
			var mapContain:UIComponent = new UIComponent;
			this.addElement(mapContain);
			
			var icon:MatSprite = new MatSprite(target[0].type, 100);
			icon.x = 70;
			icon.y = 120;
			mapContain.addChild(icon);
			
			var btn:Button = new Button;
			btn.label = "保存";
			btn.width = 50;
			btn.height = 30;
			btn.x = 45; 
			btn.y = 150;
			btn.addEventListener(MouseEvent.CLICK, onSave);
			mapContain.addChild(btn);

			map = new Sprite;
			map.graphics.lineStyle(1, 0x000000);
			map.graphics.beginFill(0xffffff);
			map.graphics.drawRect(0, 0, 320, 480);
			map.graphics.endFill();
			map.addEventListener(MouseEvent.MOUSE_UP, onMapClick);
			map.x = 150;
			map.y = 20;
			mapContain.addChild(map);
			
			line = new Shape;
			map.addChild(line);
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function onMapClick(e:MouseEvent):void
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
			render();
		}
		
		private function onDotMouseUp(event:MouseEvent):void
		{
			event.stopPropagation();
			(event.target as Sprite).stopDrag();
		}
		
		private function onDelete(event:ContextMenuEvent):void
		{
			
			for(var i:int = 0; i < dots.length; i++)
				if(dots[i] == event.contextMenuOwner)
				{
					var start:int = i%2==0 ? i-1: i;
					map.removeChild(dots[start]);
					map.removeChild(dots[start+1]);
					dots.splice(start, 2);
					render();
					return;
				}
		}
		private function onSave(e:MouseEvent):void
		{
			var startPoint:Point = new Point(dots[0].x, dots[0].y);
			var route:Array = new Array;
			for(var i:int = 0; i < dots.length; i++)
			{
				var p:Point = new Point(dots[i].x, dots[i].y).subtract(startPoint);
				route.push(p);
			}
			for each(var m:MatSprite in editTargets)
				m.route = route;
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