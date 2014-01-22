package behaviorEdit
{
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class BNode extends Sprite
	{
		public var id:int = -1;
		public var type:String = "";
		public var par:BNode = null;
		public var childNodes:Array = null;
		public var treeWidth:Number;
		public var treeHeight:Number;
		
		public var horizontalPadding:int = 100;
		public var verticalPadding:int = 10;
		protected var view:BTEditView = null;
		protected var isAcceptNode:Boolean = false;
		private var color:uint = 0;
		
		public function BNode(_type:String = "", _color:uint = 0xF0FFF0, isAccept:Boolean = false)
		{
			this.type = _type;
			this.color = _color;
			this.isAcceptNode = isAccept;
			childNodes = new Array;
			
			var bg:Sprite = new Sprite;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawRect(0, 0, 70, 30);
			bg.graphics.endFill();
			this.addChild(bg);
			
			var label:TextField = new TextField;
			label.defaultTextFormat = new TextFormat(null, 26);
			label.text = type;
			label.selectable = false;
			this.addChild(label);
			label.x = bg.width*0.5-label.textWidth*0.5;
			label.y = bg.height*0.5-label.textHeight*0.5;
		}
		
		public function init(_view:BTEditView):void
		{
			this.view = _view;	
			this.view.addChild(this);
			if(isAcceptNode)
				this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		protected function onMouseUp(e:MouseEvent):void
		{
			if(view.panel.currNode)
				onAdd(view.panel.currNode.type);
		}
		
		public function onAdd(nodeType:String):void
		{
			var node:BNode = BNodeFactory.createBNode(nodeType);
			node.init(view);
			node.par = this;
			childNodes.push(node);
			draw();
		}
		
		public function removeSelf():void
		{
			for(var i:int = 0; i < childNodes.length; i++)
				childNodes[i].removeSelf();
			
			this.par.removeChildNode(this.id);
			this.par = null;
			view.removeChild(this);
		}
		
		public function removeChildNode(id:int):void
		{
			for(var i:int = 0; i < childNodes.length; i++)
				if(childNodes[i].id == id)
				{
					childNodes.splice(i, 1);
					break;
				}
			draw();
		}
		
		public function draw():void
		{
			treeHeight = 0;
			for(var i:int = 0; i < childNodes.length; i++)
			{
				childNodes[i].draw();
				childNodes[i].x = this.x + horizontalPadding;
				childNodes[i].y = this.y + treeHeight;
				treeHeight += childNodes[i].treeHeight+verticalPadding;
			}
			treeHeight = Math.max(treeHeight, 30);
		}
	}
}