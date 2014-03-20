package mapEdit
{
	import flash.display.Shape;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	
	public class SelectControl extends EventDispatcher
	{
		public var targets:Array = null;
		public var view:MainScene = null;
		private var selectFrame:Shape = null;
		
		public function SelectControl(_view:MainScene)
		{
			targets = new Array;
			this.view = _view;
			
			this.view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		public function select(target:Component):void
		{
			if(targets.length == 1 && targets[0] == target)
				return;
			unselect();
			add(target);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		public function selectMul(targetArr:Array):void
		{
			if(targetArr.length == 0)
				return;
			unselect();
			while(targetArr.length > 0)
			{
				var i:* = targetArr.pop();
				add(i);
			}
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function isSelecting():Boolean
		{
			return selectFrame;
		}
		
		public function unselect(target:Component = null):void
		{
			for(var i:int = targets.length-1; i >= 0; i--)
				if(!target)
				{
					var o:Component = targets.pop()
					o.select(false);
					o.enablePosChangeDispatch(false);
					o.removeEventListener(Event.REMOVED_FROM_STAGE , onRemoved);
					o.contextMenu = null
				}
				else if(target == targets[i])
				{
					target.select(false);
					target.enablePosChangeDispatch(false);
					target.removeEventListener(Event.REMOVED_FROM_STAGE , onRemoved);
					targets.splice(i, 1);
					break;
				}
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		//copy and paste the selected mats to the editView.
		public function copySelect():void
		{
			var newMats:Array = new Array;
			for each(var m:Component in targets)
			{
				newMats.push(view.matsControl.add(m.type, m.x+30, m.y+30));
			}
			selectMul(newMats);
		}
		
		
		public function setSelectMatToFormation():void
		{	
			Utils.makeRenamePanel(
				function( ret:String = null ):void {
					if( !ret ) return;
					var formation:* = Data.getInstance().getFormationById( ret )
					if( formation ) 
						Alert.show("【错误】该阵型名已经存在!");
					else
					{
						Data.getInstance().updateFormationSetById( ret, format(targets) );
					}
				}, this.view.parent
			);
		}
		
		private function format(mats:Array):Array
		{
			var data:Array = new Array;
			var minX:Number = mats[0].x;
			var minY:Number = mats[0].y;
			for each(var m:EntityComponent in mats)
			{
				minX = Math.min(m.x, minX);
				minY = Math.max(m.y, minY);
				
				var point:Object = new Object;
				point.x = m.x;
				point.y = m.y;
				data.push(point);
			}
			for each(var p in data)
			{
				p.x -= minX;
				p.y -= minY;
			}
			return data;
		}
		
		
		private function onMouseDown(e:MouseEvent):void
		{
			// only start a new selection when there is no pending selection.
			// selection may get into pending state if dragged outside current view
			if(!selectFrame)
			{
				var pos:Point = view.globalToLocal(new Point(e.stageX, e.stageY));
				selectFrame = new Shape;
				selectFrame.x = pos.x;
				selectFrame.y = pos.y;
				//view.addChild(selectFrame);
			}
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			if(selectFrame)
			{
				var pos:Point = view.globalToLocal(new Point(e.stageX, e.stageY));
				selectFrame.graphics.clear();
				selectFrame.graphics.lineStyle(1);
				selectFrame.graphics.drawRect(0, 0, pos.x-selectFrame.x, pos.y-selectFrame.y);
			}
		}
		
		public function onMouseUp(e:MouseEvent):void
		{
			if(selectFrame)
			{
				selectMul(getSelectMats(selectFrame.getBounds(view)));
				//view.removeChild(selectFrame);
				selectFrame = null;
			}
		}
		
		private function getSelectMats(frame:Rectangle):Array
		{
			var result:Array = new Array;
			for each(var m:Component in view.matsControl.mats)
			{
				var bound:Rectangle = m.getBounds(view);
				if(frame.intersects(bound))
				{
					result.push(m);
				}
			}
			return result;
		}
		
		private function add(target:Component):void
		{
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("复制");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				copySelect();
			});
			var item2:ContextMenuItem = new ContextMenuItem("设为阵型");
			item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				setSelectMatToFormation();
			});
			var item3:ContextMenuItem = new ContextMenuItem("删除");
			item3.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				
				var copy:Array = targets.slice(0, targets.length);
				//Utils.dumpObject(targets);
				for each(var m:Component in copy)
				{
					view.matsControl.remove(m.sid);
				}
			});
		
			menu.addItem(item);
			menu.addItem(item2);
			menu.addItem(item3);
			
			target.parent.setChildIndex(target, target.parent.numChildren-1);
			target.contextMenu = menu;
			target.select(true);
			
			target.enablePosChangeDispatch(true);
			
			target.addEventListener(Event.REMOVED_FROM_STAGE , onRemoved);
			
			targets.push(target);
		}
		
		private function onRemoved(e:Event):void
		{
			if(e.target as Component)
				unselect(e.target as Component);
		}
	}
}