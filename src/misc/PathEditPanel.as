package misc
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.TitleWindow;
	
	public class PathEditPanel extends TitleWindow
	{
		var screenFrame:UIComponent = null;
		var line:UIComponent;
		var screenRX:int = 720;
		var screenRY:int = 1280;
		var padding:int = 30;
		
		private var parmName:String = "";
		private var dots:Array; 
		private var isCurve:Boolean;
		private var _tip:TextField;
		private var _dragging:Dot;
		private var _isArray:Boolean = false;
		
		public function PathEditPanel(parmName:String, path:Array = null, _isCurve:Boolean = true, isArray:Boolean = false)
		{
			this.title = "路径编辑";
			this.width = screenRX*0.5+padding*2;
			this.height = screenRY*0.5+padding*2 + 70;
			this.parmName = parmName;
			this.isCurve = _isCurve;
			this._isArray = isArray;
			
			var bg:UIComponent = new UIComponent;
			bg.graphics.beginFill(0xffffff);
			bg.graphics.drawRect(0, 0, this.width, this.height);
			bg.graphics.endFill();
			bg.addEventListener(MouseEvent.MOUSE_DOWN, onClick);
			this.addElement(bg);
			
			screenFrame = new UIComponent;
			screenFrame.graphics.lineStyle(1);
			screenFrame.graphics.drawRect(0, -screenRY*0.5, screenRX*0.5, screenRY*0.5);
			screenFrame.x = padding;
			screenFrame.y = padding+screenRY*0.5+30;
			this.addElement(screenFrame);
			
			line = new UIComponent;
			screenFrame.addChild(line);
			
			var btn:Button = new Button;
			btn.label = "确定";
			btn.x = 10;
			btn.y = 20;
			btn.addEventListener(MouseEvent.CLICK, onSave);
			this.addElement(btn);
			
			dots = new Array;
			if(path && path.length > 0)
			{
				for(var i:int = 0; i < path.length; i++)
				{
					var color:uint = isCurve && i%2==1 ? 0x00ff00 : 0xff0000;
					if( !isArray )
						makeDot(color, path[i].x/2, -path[i].y/2);
					else 
						makeDot(color, path[i][0]/2, -path[i][1]/2);
				}
				render();
			}
			
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function onClose(e:CloseEvent):void
		{
			PopUpManager.removePopUp(this);
		}
		
		private function onSave(e:MouseEvent):void
		{
			e.stopPropagation();
			var data:Array = new Array;
			for each(var dot in dots)
			{
				if( !this._isArray )
				{
					var p:Object = new Object;
					p.x = dot.x*2;
					p.y = -dot.y*2;
					data.push(p);
				} else {
					data.push( [dot.x*2, -dot.y*2 ]);
				}
			}
			var evt:MsgEvent = new MsgEvent(MsgEvent.EDIT_PATH);
			evt.hintMsg = parmName;
			evt.hintData = data;
			this.dispatchEvent(evt);
			PopUpManager.removePopUp(this);
		}
		
		private function onClick(e:MouseEvent):void
		{
			addDot(screenFrame.mouseX, screenFrame.mouseY);
		}
		
		private function addDot(px:int, py:int):void
		{
			if(isCurve && this.dots.length > 0)
			{
				var px1:Number = (px + this.dots[dots.length-1].x)*0.5;
				var py1:Number = (py + this.dots[dots.length-1].y)*0.5;
				this.makeDot(0x00ff00, px1, py1);
			}
			this.makeDot(0xff0000, px, py);
			this.render();
		}
		
		private function makeDot(color:uint, px:int, py:int):Sprite
		{
			var dot:Dot = new Dot(color);
			dot.addEventListener(MouseEvent.MOUSE_DOWN, onDotMouseDown);
			dot.addEventListener(MouseEvent.MOUSE_MOVE, onDotMove);
			dot.addEventListener(MouseEvent.MOUSE_UP, onDotMouseUp);
			dot.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			dot.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("删除");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDelete);
			menu.addItem(item);
			dot.contextMenu = menu;
			
			dot.setNum(dots.length);
			dot.x = px;
			dot.y = py;
			dots.push(dot);
			screenFrame.addChild(dot);
			return dot;
		}
		
		private function onMouseOver(event:MouseEvent):void {
			if (!_tip) {
				_tip = new TextField();
				screenFrame.addChild(_tip);
			}
			_tip.visible = true;
			_tip.x = screenFrame.mouseX + 5;
			_tip.y = screenFrame.mouseY + 5;
			var dot:Dot = event.currentTarget as Dot;
			var xx:Number = int(dot.x/360*720);
			var yy:Number = int(-dot.y/640*1280);
			_tip.text = "("+xx+","+yy+")";
		}
		
		private function onMouseOut(event:MouseEvent):void {
			_tip.visible = false;
		}
		
		private function removeDot(dot:Dot):void
		{
			dot.removeEventListener(MouseEvent.MOUSE_DOWN, onDotMouseDown);
			dot.removeEventListener(MouseEvent.MOUSE_MOVE, onDotMove);
			dot.removeEventListener(MouseEvent.MOUSE_UP, onDotMouseUp);
			dot.removeEventListener(MouseEvent.MOUSE_OVER, onDotMouseUp);
			dot.removeEventListener(MouseEvent.MOUSE_OUT, onDotMouseUp);
			screenFrame.removeChild(dot);
		}
		
		private function onDelete(event:ContextMenuEvent):void
		{
			for(var i:int = 0; i < dots.length; i++)
				if(dots[i] == event.contextMenuOwner)
					if(isCurve)
					{
						var relatDotIndex:int = (i==0 || i%2 == 1) ? i : i-1;
						removeDot(dots[relatDotIndex]);
						removeDot(dots[relatDotIndex+1]);
						dots.splice(relatDotIndex, 2);
						break;
					}
					else
					{
						removeDot(dots[i]);
						dots.splice(i, 1);
						break;
					}
			render();
			orderDots();
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
			_dragging = event.currentTarget as Dot;
			(event.currentTarget as Sprite).startDrag();
		}
		private function onDotMove(event:MouseEvent):void
		{
			render();
			if (event.currentTarget == _dragging) {
				onMouseOver(event);
			}
		}
		private function onDotMouseUp(event:MouseEvent):void
		{
			event.stopPropagation();
			(event.currentTarget as Sprite).stopDrag();
			_dragging = null;
		}
		
		private function render():void
		{
			if(dots.length > 1)
			{
				line.graphics.clear();
				line.graphics.lineStyle(1);
				line.graphics.moveTo(dots[0].x, dots[0].y);
				if(isCurve)
				{
					for(var i:int = 2; i < dots.length; )
					{
						line.graphics.curveTo(dots[i-1].x, dots[i-1].y, dots[i].x, dots[i].y);
						i+=2;
					}
				}
				else
					for(var i:int = 1; i < dots.length; i++)
						line.graphics.lineTo(dots[i].x, dots[i].y);
				
			}
		}
		
		
	}
}