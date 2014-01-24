package behaviorEdit
{
	import flash.events.Event;
	import flash.geom.Point;

	public class SeqBNode extends BNode
	{
		public function SeqBNode()
		{
			super(BType.BTYPE_SEQ, 0xA020F0, true);
			
			//this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:Event):void
		{
			drawGraph();
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
			if(childNodes.length > 0)
			{
				trace(childNodes.length);
				this.graphics.clear();
				this.graphics.lineStyle(2);
				connect(convertToLocal(this.getRightMiddle()), convertToLocal(childNodes[0].getLeftMiddle()));
				for(var i:int = 0; i < childNodes.length-1; i++)
				{
					connect(convertToLocal(childNodes[i].getBottomMiddle()), convertToLocal(childNodes[i+1].getTopMiddle()));
				}
			}
			
		}
		
		private function convertToLocal(p:Point):Point
		{
			return new Point(p.x-this.x, p.y-this.y);
		}
		
		private function connect(p1:Point, p2:Point):void
		{
			this.graphics.lineStyle(2);
			this.graphics.moveTo(p1.x, p1.y);
			this.graphics.lineTo(p2.x, p2.y);
			//trace("connect"+p1+" "+p2);
		}
	}
}