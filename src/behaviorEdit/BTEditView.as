package behaviorEdit
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
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
			rootNode.setPos(50, 20);
			this.addNode(rootNode);
			
			EventManager.getInstance().addEventListener(BTEvent.TREE_CHANGE, onTreeChange);
			EventManager.getInstance().addEventListener(BTEvent.LAID, onNodeLaid);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		public function init(data:Object):void
		{
			clear();
			if(data && data.hasOwnProperty("type"))
				initNode(rootNode, data);
		}
		
		public function clear():void
		{
			rootNode.removeFromView();
		}
		
		public function initNode(par:BNode, nodeData:Object):void
		{
			var node:BNode = BNodeFactory.createBNode(nodeData.type);
			this.addNode(node);
			node.initData(nodeData.data);
			par.add(node);
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
			var children:Array = nodeData.children as Array;
			for(var i:int = 0; i < children.length; i++)
				initNode(node, children[i]);
		}
		
		public function addNode(childNode:BNode):void
		{
			childNode.setView(this);
			childNode.active();
			this.addChild(childNode);
		}
		
		public function remove():void
		{
			EventManager.getInstance().removeEventListener(BTEvent.TREE_CHANGE, onTreeChange);
			EventManager.getInstance().removeEventListener(BTEvent.LAID, onNodeLaid);
		}
		
		public function export():Object
		{
			if(rootNode.childNodes.length > 0)
				return getExportData(rootNode.childNodes[0]);
			return null;
		}
		
		private function getExportData(node:BNode):Object
		{
			var nodeData:Object = new Object;
			nodeData.type = node.type;
			nodeData.data = node.exportData();
			nodeData.children = new Array;
			for(var i:int = 0; i < node.childNodes.length; i++)
				nodeData.children.push(getExportData(node.childNodes[i]));
			return nodeData;
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
			
			var laidOnNode:BNode = find(rootNode, function(n:BNode):Boolean{
				var childRect:Rectangle = new Rectangle(n.x+n.boundingBox.width, n.y, 100, n.boundingBox.height);
				var targetPos:Point = new Point(node.x, node.y);
				return n != node && n.getInteractiveRect().containsPoint(targetPos);
			});
			if(laidOnNode && laidOnNode.par)
			{
				laidOnNode.par.onDragIn(node);
			}
			else(!laidOnNode)
			{
				var nodeNeedChild:BNode = find(rootNode, function(n:BNode):Boolean{
					var childRect:Rectangle = new Rectangle(n.x+n.boundingBox.width, n.y, 100, n.boundingBox.height);
					return n != node && childRect.containsPoint(new Point(node.x, node.y));
				});
				if(nodeNeedChild)
					nodeNeedChild.onDragIn(node);
			}
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
		private function find(node:BNode, condFunc:Function):BNode
		{
			if(condFunc(node))
				return node;
			else
				for each(var n:BNode in node.childNodes)
				{
					var result:BNode = find(n, condFunc);
					if(result)
						return result;
				}
			return null;
		}
	
		private function onMouseUp(e:MouseEvent):void
		{
			EventManager.getInstance().dispatchEvent(e);
		}
	}
}