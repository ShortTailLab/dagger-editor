package behaviorEdit
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.Parallel;
	import mx.events.EffectEvent;
	
	import editEntity.MatSprite;
	
	import flashx.textLayout.formats.Float;
	
	import manager.EventManager;

	public class BNode extends UIComponent
	{
		public var nodeId:int = -1;
		public var type:String = "";
		public var par:BNode = null;
		protected var enableLay:Boolean = false;
		
		public var treeWidth:Number = 0.0;
		public var treeHeight:Number = 0.0;
		
		protected var nodeWidth:Number = 100;
		protected var nodeHeight:Number = 70;
		
		public var horizontalPadding:int = 30;
		public var verticalPadding:int = 30;
		public var childNodes:Array = null;
		protected var view:BTEditView = null;
		protected var isAcceptNode:Boolean = false;
		protected var color:uint = 0;
		
		private var desX:Number = 0.0;
		private var desY:Number = 0.0;
		
		public var enableDebug:Boolean = false;;
		
		public function BNode(_type:String = "", _color:uint = 0xF0FFF0, isAccept:Boolean = false, enableLayNode:Boolean = false)
		{
			this.type = _type;
			this.color = _color;
			this.isAcceptNode = isAccept; 
			this.enableLay = enableLayNode;
			childNodes = new Array;
			
			initShape();
			
			this.width = nodeWidth;
			this.height = nodeHeight;
			
		}
		
		protected function initShape():void
		{
			var bg:Sprite = new Sprite;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawRect(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			this.addChild(bg);
			
			var label:TextField = new TextField;
			label.defaultTextFormat = new TextFormat(null, 24);
			label.text = type;
			label.selectable = false;
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			this.addChild(label);
			label.x = bg.width*0.5-label.textWidth*0.5;
			label.y = bg.height*0.5-label.textHeight*0.5;
		}
		
		public function init(_view:BTEditView):void
		{
			this.view = _view;	
			this.view.addChild(this);
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			
			if(isAcceptNode)
				this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			var menu:ContextMenu = new ContextMenu;
			var btn:ContextMenuItem = new ContextMenuItem("删除");
			btn.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				BNode(e.contextMenuOwner).removeSelf();
				EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
			});
			menu.addItem(btn);
			this.contextMenu = menu;
		}
		
		public function initPos(dx:Number, dy:Number):void
		{
			this.x = desX = dx;
			this.y = desY = dy;
		}
		
		public function initData(data:Object):void
		{
		}
		
		public function exportData():Object
		{
			return null;
		}
		
		public function update(dt:Number):void
		{
			for each(var n:BNode in childNodes)
				n.update(dt);
			drawGraph();
		}
		
		public function getInteractiveRect():Rectangle
		{
			return new Rectangle(this.x+nodeWidth, this.y-nodeHeight, nodeWidth, treeHeight+nodeHeight);
		}
		
		public function getChildNodeIndex(node:BNode):int
		{
			for(var i:int = 0; i < childNodes.length; i++)
				if(childNodes[i] == node)
					return i;
			return -1;
		}
		
		public function getCenterPoint():Point
		{
			return new Point(this.x+(nodeWidth-horizontalPadding)*0.5, this.y+(nodeHeight-verticalPadding)*0.5);
		}
		public function getLeftMiddle():Point
		{
			return new Point(this.x, this.y+(nodeHeight-verticalPadding)*0.5);
		}
		public function getRightMiddle():Point
		{
			return new Point(this.x+(nodeWidth-horizontalPadding), this.y+(nodeHeight-verticalPadding)*0.5);
		}
		
		public function getTopMiddle():Point
		{
			return new Point(this.x+(nodeWidth-horizontalPadding)*0.5, this.y);
		}
		public function getBottomMiddle():Point
		{
			return new Point(this.x+(nodeWidth-horizontalPadding)*0.5, this.y+(nodeHeight-verticalPadding));
		}
		
		private var isPressing:Boolean = false;
		protected function onMouseDown(e:MouseEvent):void
		{
			isPressing = true;
			EventManager.getInstance().addEventListener(MouseEvent.MOUSE_MOVE, onPanelMouseMove);
			EventManager.getInstance().addEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
		}
		
		protected function onPanelMouseMove(e:MouseEvent):void
		{
			if(isPressing)
			{
				this.x = view.mouseX-nodeWidth*0.5;
				this.y = view.mouseY-nodeHeight*0.5;
				draw();
			}
			
		}
		
		protected function onMouseUp(e:MouseEvent):void
		{
			if(view.panel.currNode)
				onAdd(view.panel.currNode.type);
		}
		
		protected function onPanelMouseUp(e:MouseEvent):void
		{
			if(isPressing)
			{
				EventManager.getInstance().removeEventListener(MouseEvent.MOUSE_MOVE, onPanelMouseMove);
				EventManager.getInstance().removeEventListener(MouseEvent.MOUSE_UP, onPanelMouseUp);
				var event:BTEvent = new BTEvent(BTEvent.LAID);
				event.bindingNode = this;
				EventManager.getInstance().dispatchEvent(event);
				isPressing = false;
			}
			
		}
		
		public function onLay(node:BNode):void
		{
			if(enableLay)
			{
				for(var i:int = 0; i < childNodes.length; i++)
					if(node.y < childNodes[i].y)
						break;
				
				if(node.par == this && getChildNodeIndex(node) < i)
					i--;
				node.par.removeChildNode(node.nodeId);
				childNodes.splice(i, 0, node);
				
				node.par = this;
			}
			
		}
		
		public function onAdd(nodeType:String):void
		{
			var node:BNode = BNodeFactory.createBNode(nodeType);
			node.init(view);
			add(node);
		}
		
		public function add(node:BNode):void
		{
			node.initPos(this.x, this.y);
			node.par = this;
			childNodes.push(node);
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
		public function removeSelf():void
		{
			while(childNodes.length > 0)
				BNode(childNodes.pop()).removeSelf();
			if(this.par)
			{
				this.par.removeChildNode(this.nodeId);
				this.par = null;
			}
			
			view.removeChild(this);
		}
		
		public function removeChildNode(id:int):void
		{
			for(var i:int = 0; i < childNodes.length; i++)
				if(childNodes[i].nodeId == id)
				{
					childNodes.splice(i, 1);
					return;
				}
		}
		
		public function drawWithAnim():void
		{
			treeWidth = 0;
			treeHeight = 0;
			if(childNodes.length > 0)
			{
				var parActions:Parallel = new Parallel;
				for(var i:int = 0; i < childNodes.length; i++)
				{
					childNodes[i].desX = this.desX + nodeWidth;
					childNodes[i].desY = this.desY + treeHeight ;
					var action:Move = new Move(childNodes[i]);
					action.xFrom = childNodes[i].x;
					action.yFrom = childNodes[i].y;
					action.xTo = childNodes[i].desX;
					action.yTo = childNodes[i].desY;
					action.duration = 200;
					parActions.addChild(action);
					
					childNodes[i].drawWithAnim();
					treeWidth = Math.max(treeWidth, nodeWidth + childNodes[i].treeWidth);
					treeHeight += childNodes[i].treeHeight;
				}
				parActions.addEventListener(EffectEvent.EFFECT_END, onMoveEnd);
				parActions.play();
			}
			else
				drawGraph();
			
			treeWidth = Math.max(treeWidth, nodeWidth);
			treeHeight = Math.max(treeHeight, nodeHeight);
			
			if(false)
			{
				this.graphics.clear();
				this.graphics.lineStyle(1);
				this.graphics.drawRect(nodeWidth, 0, treeWidth, treeHeight);
			}
		}
		
		private function onMoveEnd(e:EffectEvent):void
		{
			drawGraph();
		}
		
		public function draw():void
		{
			view.setChildIndex(this, view.numChildren-1);
			treeHeight = 0;
			for(var i:int = 0; i < childNodes.length; i++)
			{
				childNodes[i].x = this.x + nodeWidth;
				childNodes[i].y = this.y + treeHeight;
				childNodes[i].draw();
				treeWidth = Math.max(treeWidth, childNodes[i].treeWidth);
				treeHeight += childNodes[i].treeHeight;
			}
			treeWidth = Math.max(treeWidth, nodeWidth);
			treeHeight = Math.max(treeHeight, nodeHeight);
		}
		
		public function drawGraph():void
		{
			
		}
		
		public function convertToLocal(p:Point):Point
		{
			return new Point(p.x-this.x, p.y-this.y);
		}
		
		public function connect(p1:Point, p2:Point):void
		{
			this.graphics.lineStyle(2);
			this.graphics.moveTo(p1.x, p1.y);
			this.graphics.lineTo(p2.x, p2.y);
		}
		
		public function squareConnect(p1:Point, p2:Point):void
		{
			this.graphics.lineStyle(2);
			this.graphics.moveTo(p1.x, p1.y);
			this.graphics.lineTo(p1.x, p2.y);
			this.graphics.lineTo(p2.x, p2.y);
		}
	}
}