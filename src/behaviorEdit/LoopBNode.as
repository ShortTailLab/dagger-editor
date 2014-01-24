package behaviorEdit
{
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class LoopBNode extends BNode
	{
		public function LoopBNode()
		{
			super(BType.BTYPE_LOOP, 0xffff00, true);
		}
		
		override protected function initShape():void
		{
			var bg:Shape = new Shape;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawEllipse(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			this.addChild(bg);
			
			var label:TextField = new TextField;
			label.defaultTextFormat = new TextFormat(null, 22);
			label.text = type;
			label.selectable = false;
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			this.addChild(label);
			label.x = bg.width*0.5-label.textWidth*0.5;
			label.y = bg.height*0.5-label.textHeight*0.5;
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
		
		override public function drawGraph():void
		{
			this.graphics.clear();
			if(childNodes.length > 0)
			{
				this.graphics.lineStyle(2);
				var startPoint:Point = convertToLocal(this.getRightMiddle());
				connect(startPoint, convertToLocal(childNodes[0].getLeftMiddle()));
				for(var i:int = 0; i < childNodes.length-1; i++)
				{
					connect(convertToLocal(childNodes[i].getBottomMiddle()), convertToLocal(childNodes[i+1].getTopMiddle()));
				}
				var lastPos:Point = convertToLocal(childNodes[childNodes.length-1].getBottomMiddle());
				var bottomPos:Point = new Point(lastPos.x, lastPos.y+10);
				connect(lastPos, bottomPos);
				squareConnect(new Point(startPoint.x+5, startPoint.y), bottomPos);
			}
			else
			{
				var rpos:Point = convertToLocal(this.getRightMiddle());
				connect(rpos, new Point(this.nodeWidth, rpos.y));
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y, 8);
			}
			
		}
	}
}