package behaviorEdit
{
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.controls.Alert;

	public class CondBNode extends BNode
	{
		public function CondBNode()
		{
			super(BType.BTYPE_COND, 0x1E90FF, true, true);
			
			
		}
		
		override protected function initShape():void
		{
			var bg:Shape = new Shape;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.moveTo(getTopMiddle().x, getTopMiddle().y);
			bg.graphics.lineTo(getRightPoint().x, getRightPoint().y);
			bg.graphics.lineTo(getBottomMiddle().x, getBottomMiddle().y);
			bg.graphics.lineTo(getLeftPoint().x, getLeftPoint().y);
			bg.graphics.lineTo(getTopMiddle().x, getTopMiddle().y);
			bg.graphics.endFill();
			this.addChild(bg);
			
			var label:TextField = new TextField;
			label.defaultTextFormat = new TextFormat(null, 20);
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
			if(this.childNodes.length < 2 || node.par == this)
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
		
		override public function onAdd(nodeType:String):void
		{
			if(childNodes.length < 2)
			{
				super.onAdd(nodeType);
			}
			else
				Alert.show("条件节点只能添加两个子节点！");
			
		}
		
		override public function drawGraph():void
		{
			this.graphics.clear();
			if(childNodes.length > 0)
			{
				this.graphics.lineStyle(2);
				Utils.horConnect(this, convertToLocal(this.getRightPoint()), convertToLocal(childNodes[0].getLeftPoint()));
				for(var i:int = 0; i < childNodes.length-1; i++)
				{
					var startPoint:Point = convertToLocal(this.getRightPoint());
					Utils.squareConnect(this, new Point(startPoint.x+5, startPoint.y), convertToLocal(childNodes[i+1].getLeftPoint()));
				}
			}
			else
			{
				var rpos:Point = convertToLocal(this.getRightPoint());
				Utils.squareConnect(this, rpos, new Point(this.nodeWidth, rpos.y-15));
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y-15, 8);
				Utils.squareConnect(this, rpos, new Point(this.nodeWidth, rpos.y+15));
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y+15, 8);
			}
		}
		
	}
}