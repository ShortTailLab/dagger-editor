package behaviorEdit
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.controls.Button;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	
	import manager.EventManager;

	public class ExecBNode extends BNode
	{
		
		private var inputLabel:TextArea;
		private var menu:Sprite;
		private var container:UIComponent = null;
		
		private var parmNodes:Array;
		
		public function ExecBNode()
		{
			super(BType.BTYPE_EXEC, 0xF0FFF0, true, false, BNodeDrawStyle.PAR_DRAW);
		}
		
		
		override public function init(_view:BTEditView):void
		{
			super.init(_view);
			
			label.defaultTextFormat = new TextFormat(null, 16);
			label.x = 5;
			label.y = 5;
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseClick);
			
			/*inputLabel = new TextArea();
			inputLabel.width = 150;
			inputLabel.height = 60;
			inputLabel.x = 10;
			inputLabel.y = 20;
			inputLabel.addEventListener(MouseEvent.MOUSE_DOWN, onLabelMouseDown);
			this.addChild(inputLabel);*/
		}
		
		override public function onAdd(nodeType:String):void
		{
			if(childNodes.length < parmNodes.length)
			{
				super.onAdd(nodeType);
			}
		}
		
		private function onMouseClick(e:MouseEvent):void
		{
			e.stopPropagation();
			displayBaseMenu();
		}
		
		public function displayBaseMenu():void
		{
			if(menu)
			{
				this.removeChild(menu);
				menu = null;
			}
			
			if(Data.getInstance().behaviorBaseNode)
			{
				menu = new Sprite;
				var i:int = 0;
				var h:Number = 0.0;
				var w:Number = 0.0;
				for(var item:String in Data.getInstance().behaviorBaseNode)
				{
					
					var label:TextField = Utils.getLabel(item, 0, 0, 16);
					label.selectable = false;
					label.border = true;
					label.width = label.textWidth+10;
					label.height = label.textHeight+5;
					label.x = 0;
					label.y = h;
					label.addEventListener(MouseEvent.MOUSE_DOWN, onBtnClick);
					menu.addChild(label);
					h += label.textHeight+5;
					w = Math.max(w, label.textWidth+10);
				}
				menu.graphics.beginFill(0, 0.5);
				menu.graphics.drawRect(0, 0, w, h);
				menu.graphics.endFill();
				menu.x = nodeWidth-10;
				menu.y = -this.y+10;
				this.addChild(menu);
			}
		}
		
		public function closeMenu():void
		{
			if(menu)
			{
				this.removeChild(menu);
				menu = null;
			}
			
		}
		
		private function onBtnClick(e:MouseEvent):void
		{
			e.stopPropagation();
			var label:TextField = e.currentTarget as TextField;
			initExecType(label.text);
			closeMenu();
		}
		
		private function initExecType(type:String):void
		{
			var sType:String = type.split(".").pop();
			label.text = sType;
			label.width = label.textWidth+10;
			label.height = label.textHeight + 10;
			
			if(container)
				this.removeChild(container);
			container = new UIComponent;
			container.y = label.height;
			this.addChild(container);
			
			parmNodes = new Array;
			var gridWidth:int = 45;
			var gridHeight:int = 30;
			var nodeData:Object = Data.getInstance().behaviorBaseNode[type];
			var i:int = 0;
			for each(var item in nodeData)
			{
				if(item.type == "node")
				{
					parmNodes.push(item.name);
				}
				else if(item.type == "float" || item.type == "string")
				{
					var p1:Point = Utils.makeGrid2(new Point(0, 0), gridWidth, gridHeight, 2, i++); 
					var tt:TextField = Utils.getLabel(item.name+":", p1.x, p1.y, 14);
					tt.selectable = false;
					container.addChild(tt);
					var p2:Point = Utils.makeGrid2(new Point(0, 0), gridWidth, gridHeight, 2, i++); 
					var input:TextInput = new TextInput;
					input.height = 20;
					input.width = 40;
					input.x = p2.x;
					input.y = p2.y;
					input.addEventListener(MouseEvent.MOUSE_DOWN, onInputDown);
					container.addChild(input);
				}
			}
			nodeWidth = Math.max(2*gridWidth, label.width)+horizontalPadding;
			var h:int = i > 0 ? gridHeight*(int(i/2)) : 0;
			nodeHeight = Math.max(100, label.height+h+verticalPadding);
			updateBg();
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
		private function onInputDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		
		override public function initData(data:Object):void
		{
			if(data)
				inputLabel.text = data.content;
		}
		
		override public function exportData():Object
		{
			if(inputLabel.text != "")
			{
				var obj:Object = new Object;
				obj.content = inputLabel.text;
				return obj;
			}
			return null;
		}
		
		override public function drawGraph():void
		{
			this.graphics.clear();
			if(childNodes.length > 0)
			{
				this.graphics.lineStyle(2);
				Utils.horConnect(this, convertToLocal(this.getRightPoint()), convertToLocal(childNodes[0].getLeftPoint()), 2);
				for(var i:int = 0; i < childNodes.length-1; i++)
				{
					var startPoint:Point = convertToLocal(this.getRightPoint());
					Utils.squareConnect(this, new Point(startPoint.x+5, startPoint.y), convertToLocal(childNodes[i+1].getLeftPoint()), 2);
				}
			}
			else
			{
				
				var rpos:Point = convertToLocal(this.getRightPoint());
				Utils.squareConnect(this, rpos, new Point(this.nodeWidth, rpos.y));
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y, 8);
				Utils.squareConnect(this, rpos, new Point(this.nodeWidth, rpos.y+30));
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y+30, 8);
			}
		}
		
		private function onLabelMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		
	}
}