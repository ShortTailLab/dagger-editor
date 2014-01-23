package behaviorEdit
{
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	import manager.EventManager;
	
	public class BTEditView extends UIComponent
	{
		public var panel:BTEditPanel = null;
		private var rootNode:RootBNode = null;
		
		public function BTEditView(_panel:BTEditPanel)
		{
			panel = _panel; 
			
			rootNode = new RootBNode;
			rootNode.initPos(50, 50);
			rootNode.init(this);
			
			EventManager.getInstance().addEventListener(BTEvent.TREE_CHANGE, onTreeChange);
			EventManager.getInstance().addEventListener(BTEvent.LAID, onNodeLaid);
		}
		
		private function onTreeChange(e:BTEvent):void
		{
			rootNode.drawWithAnim();
			this.width = rootNode.x + rootNode.treeWidth;
			this.height = rootNode.y + rootNode.treeHeight;
		}
		
		private function onNodeLaid(e:BTEvent):void
		{
			var node:BNode = e.bindingNode;
			
			var result:BNode = check(rootNode, function(n:BNode):Boolean{
				return n.getInteractiveRect().containsPoint(new Point(node.x, node.y));
			});
			if(result)
				result.onLay(node);
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
		private function check(node:BNode, condFunc:Function):BNode
		{
			if(condFunc(node))
				return node;
			else
				for each(var n:BNode in node.childNodes)
				{
					var result:BNode = check(n, condFunc);
					if(result)
						return result;
				}
			return null;
		}
		
	}
}