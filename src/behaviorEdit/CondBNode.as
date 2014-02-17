package behaviorEdit
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.controls.Alert;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.UIComponent;

	public class CondBNode extends BNode
	{
		private var inputLabel:TextArea;
		
		private var sign1:Sprite = null;
		private var sign2:Sprite = null;
		private var boolSwitch:Boolean = true;
		
		public function CondBNode()
		{
			super(BType.BTYPE_COND, 0x1E90FF, true, true);
			
		}
		
		override protected function initShape():void
		{
			bg = new Sprite;
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.moveTo(getTopMiddle().x, getTopMiddle().y);
			bg.graphics.lineTo(getRightPoint().x, getRightPoint().y);
			bg.graphics.lineTo(getBottomMiddle().x, getBottomMiddle().y);
			bg.graphics.lineTo(getLeftPoint().x, getLeftPoint().y);
			bg.graphics.lineTo(getTopMiddle().x, getTopMiddle().y);
			bg.graphics.endFill();
			this.addChild(bg);
			
			label = new TextField;
			label.defaultTextFormat = new TextFormat(null, 20);
			label.text = type;
			label.selectable = false;
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			
			this.addChild(label);
			label.x = bg.width*0.5-label.textWidth*0.5;
			label.y = bg.height*0.5-label.textHeight*0.5;
		}
		
		/*override public function init(_view:BTEditView):void
		{
			super.init(_view);
			nodeWidth = 200;
			nodeHeight = 120;
			
			bg.graphics.clear();
			bg.graphics.lineStyle(1);
			bg.graphics.beginFill(color);
			bg.graphics.drawRect(0, 0, nodeWidth-horizontalPadding, nodeHeight-verticalPadding);
			bg.graphics.endFill();
			label.setTextFormat(new TextFormat(null, 16));
			label.x = 5;
			label.y = 5;
			
			inputLabel = new TextArea();
			inputLabel.width = 150;
			inputLabel.height = 60;
			inputLabel.x = 10;
			inputLabel.y = 20;
			inputLabel.addEventListener(MouseEvent.MOUSE_DOWN, onLabelMouseDown);
			this.addChild(inputLabel);
		}*/
		
		override public function initData(data:Object):void
		{
			if(data)
				inputLabel.text = data.cond;
		}
		
		override public function exportData():Object
		{
			var obj:Object = new Object;
			obj.cond = inputLabel.text;
			obj.first = boolSwitch;
			return obj;
		}
		
		private function onLabelMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
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
				Utils.horConnect(this, convertToLocal(this.getRightPoint()), convertToLocal(childNodes[0].getLeftPoint()), 2, color);
				for(var i:int = 0; i < childNodes.length-1; i++)
				{
					var startPoint:Point = convertToLocal(this.getRightPoint());
					Utils.squareConnect(this, new Point(startPoint.x+5, startPoint.y), convertToLocal(childNodes[i+1].getLeftPoint()), 2, color);
				}
			}
			else
			{
				var rpos:Point = convertToLocal(this.getRightPoint());
				Utils.squareConnect(this, rpos, new Point(this.nodeWidth, rpos.y), 2, color);
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y, 8);
				Utils.squareConnect(this, rpos, new Point(this.nodeWidth, rpos.y+30), 2, color);
				this.graphics.drawCircle(this.nodeWidth+8, rpos.y+30, 8);
			}
			
			updateSwitcher();
		}
		
		private function updateSwitcher():void
		{
			if(sign1)
			{
				this.removeChild(sign1);
				sign1 = null;
			}
			if(sign2)
			{
				this.removeChild(sign2);
				sign2 = null;
			}
			
			if(childNodes.length >= 1)
			{
				sign1 = makeSigh(boolSwitch);
				sign1.x = convertToLocal(this.getRightPoint()).x+5;
				sign1.y = convertToLocal(childNodes[0].getLeftPoint()).y-sign1.height;
				this.addChild(sign1);
			}
			if(childNodes.length >= 2)
			{
				sign2 = makeSigh(!boolSwitch);
				sign2.x = convertToLocal(this.getRightPoint()).x+5;
				sign2.y = convertToLocal(childNodes[1].getLeftPoint()).y-sign1.height;
				this.addChild(sign2);
			}
		}
		
		private function makeSigh(value:Boolean):Sprite
		{
			var label:String = value ? "Y" : "N";
			var t:TextField = new TextField;
			t.defaultTextFormat = new TextFormat(null, 20, 0xff0000);
			t.text = label;
			t.selectable = false;
			t.width = t.textWidth+5;
			t.height = t.textHeight+5;
			
			var bg:Sprite = new Sprite;
			bg.graphics.beginFill(0, 0);
			bg.graphics.drawRect(0, 0, t.textWidth, t.textHeight);
			bg.graphics.endFill();
			bg.addChild(t);
			return bg;
		}
		
	}
}