package behaviorEdit
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.controls.TextArea;
	import mx.controls.TextInput;

	public class LoopBNode extends BNode
	{
		private var input:TextInput;
		
		public function LoopBNode()
		{
			super(BType.BTYPE_LOOP, 0xffff00, true , true, BNodeDrawStyle.LOOP_DRAW);
		}
		
		override protected function initShape():void
		{
			bg = new Sprite;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawEllipse(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			this.addChild(bg);
			
			label = new TextField;
			label.defaultTextFormat = new TextFormat(null, 22);
			label.text = type;
			label.selectable = false;
			
			this.addChild(label);
			label.x = bg.width*0.5-label.textWidth*0.5;
			label.y = bg.height*0.5-label.textHeight*0.5;
		}
		
		/*override public function init(_view:BTEditView):void
		{
			super.init(_view);
			nodeWidth = 110;
			nodeHeight = 90;
			
			bg.graphics.clear();
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawEllipse(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			
			label.text = "循环次数:"
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			label.x = 8;
			label.y = 10;
			label.setTextFormat(new TextFormat(null, 14));
			
			input = new TextInput;
			input.width = 50;
			input.height = 20;
			input.x = 15;
			input.y = 28;
			input.addEventListener(MouseEvent.MOUSE_DOWN, onLabelMouseDown);
			this.addChild(input);
		}*/
		
		override public function initData(data:Object):void
		{
			if(data)
				input.text = data.times;
		}
		
		override public function exportData():Object
		{
			var obj:Object = new Object;
			obj.times = input.text;
			return obj;
		}
		
		private function onLabelMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		override public function onLay(node:BNode):void
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
}