package behaviorEdit
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.TextArea;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import spark.components.ComboBox;
	import spark.components.TextInput;
	
	import behaviorEdit.bnodePainter.ParGraphPainter;
	
	import manager.EventManager;

	public class ExecBNode extends BNode
	{
		private var inputLabel:TextArea;
		private var container:UIComponent = null;
		private var hasInit:Boolean = false;
		
		public var parmNodes:Array = null;
		private var parmInput:Array = null;
		
		private var execType:String = "";
		private var nodeData:Object;
		
		public function ExecBNode()
		{
			super(BType.BTYPE_EXEC, 0xF0FFF0, true, true, 0);
			this.horizontalPadding = 45;
			this.graphPainter = new ParGraphPainter(this);
			this.graphPainter.setDefaultColor(0);
		}
		//this should called when it added to bteditview
		override public function active():void
		{
			super.active();
			
			label.defaultTextFormat = new TextFormat(null, 16);
			label.x = 5;
			label.y = 5;
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		override protected function onMouseUp(e:MouseEvent):void
		{
			if(hasMouseDown && !isPressing)
			{
				var window:ExecTypePanel = new ExecTypePanel;
				window.addEventListener(MsgEvent.EXEC_TYPE, onSelectType);
				
				PopUpManager.addPopUp(window, this, true);
				PopUpManager.centerPopUp(window);
			}
			if(view.panel.currSelectBNode)
				onAdd(view.panel.currSelectBNode.type);
		}
		
		override public function initData(data:Object):void
		{
			if(data && data.execType && data.execType != "")
			{
				this.setExecType(data.execType);
				var parmData:Array = data.parm as Array;
				for each(var item in parmInput)
				{
					for each(var p in parmData)
						if(p.name == item.name)
						{
							if(item.type == "bool")
								ComboBox(item.box).selectedItem = p.value;
							else if(item.type == "array_ccp" || item.type == "array_ccp_curve" )
							{
								TextInput(item.input).text = JSON.stringify(p.path);
								item.path = p.path;
							}
							else if(item.type != "node")
								TextInput(item.input).text = p.value;
							break;
						}
				}
			}
		}
		
		override public function exportData():Object
		{
			var obj:Object = new Object;
			obj.execType = this.execType;
			obj.parm = new Array;
			for each(var o:Object in parmInput)
			{
				var data:Object = new Object;
				data.name = o.name;
				data.type = o.type;
				if(data.type == "bool")
				{
					data.value = ComboBox(o.box).selectedItem;
				}
				else if(data.type == "array_ccp" || data.type == "array_ccp_curve")
				{
					data.path = o.path;
				}
				else if(data.type != "node")
					data.value = TextInput(o.input).text;
					
				obj.parm.push(data);
				
			}
			return obj;
		}
		
		override public function drawGraph():void
		{
			if(parmNodes && parmNodes.length > 0)
			{
				//cal the fit horizontalpadding
				var selfPoint:Point = convertToLocal(this.getRightPoint());
				var maxWidth:int = 0;
				var labels:Array = new Array;
				for(var i:int = 0; i <  parmNodes.length; i++)
				{
					var label:TextField = new TextField;
					label.defaultTextFormat = new TextFormat(null, 16, 0xff0000);
					label.text = parmNodes[i];
					labels.push(label);
					maxWidth = Math.max(maxWidth, label.textWidth+10);
				}
				this.horizontalPadding = maxWidth;
				
				super.drawGraph();
				var endPoint:Point = new Point(this.boundingBox.width, selfPoint.y);
				for(var j:int = 0; j < labels.length; j++)
				{
					if(j < this.childNodes.length)
						endPoint = this.convertToLocal(BNode(this.childNodes[j]).getLeftPoint());
					else if(j > 0)
						endPoint.y += 30;
					labels[j].x = endPoint.x - label.textWidth-3;
					labels[j].y = endPoint.y -label.textHeight-3;
					graphPainter.getCanvas().addChild(labels[j]);
				}
			}
			else
			{
				graphPainter.clear();
				this.horizontalPadding = 30;
			}
		}
		
		private function onSelectType(e:MsgEvent):void
		{
			setExecType(e.hintMsg);
		}
		
		
		private function setExecType(type:String):void
		{
			var nodes:Array = Data.getInstance().behaviorNodes as Array;
			for each(var d in nodes)
			if(d.func == type)
			{
				nodeData = d.args as Array;
				break;
			}
			if(!nodeData)
			{
				return;
			}
			
			hasInit = true;
			execType = type;
			
			parmNodes = new Array;
			parmInput = new Array;
			var interval:int = 30;
			var yRecord:int = 0;
			
			var targetNode:Object;
			var sType:String = type.split(".").pop();
			label.text = sType;
			label.width = label.textWidth+10;
			label.height = label.textHeight + 10;
			
			if(container)
				this.removeChild(container);
			container = new UIComponent;
			container.y = label.height;
			this.addChild(container);
			
			this.clearAllChildren();
			
			var i:int = 0;
			for each(var item in nodeData)
			{
				if(item.type == "node")
				{
					parmNodes.push(item.name);
					var parmData:Object = new Object;
					parmData.name = item.name;
					parmData.type = item.type;
					parmInput.push(parmData);
				}
				else if(item.type == "ccsize")
				{
					addInput(item.name+" w", yRecord, item.type);
					yRecord += 30;
					addInput(item.name+" h", yRecord, item.type);
					yRecord += 30;
				}
				else if(item.type == "ccp")
				{
					addInput(item.name+" x", yRecord, item.type);
					yRecord += 30;
					addInput(item.name+" y", yRecord, item.type);
					yRecord += 30;
				}
				else
				{
					addInput(item.name, yRecord, item.type);
					yRecord += 30;
				}
				
			}
			nodeWidth = Math.max(120, label.width);
			nodeHeight = Math.max(40, label.height+yRecord);
			
			childNodeLimit = parmNodes.length;
			updateBg();
			EventManager.getInstance().dispatchEvent(new BTEvent(BTEvent.TREE_CHANGE));
		}
		
		private function addInput(name:String, py:int, type:String):void
		{
			var tt:TextField = Utils.getLabel(name+":", 0, py, 14);
			tt.height = tt.textHeight+5;
			tt.selectable = false;
			container.addChild(tt);
			
			var parmData:Object = new Object;
			parmData.name = name;
			parmData.type = type;
			
			if(type == "bool")
			{
				var boxData:ArrayCollection = new ArrayCollection(["true", "false"]);
				var box:ComboBox = new ComboBox;
				box.dataProvider = boxData;
				box.selectedIndex = 0;
				box.width = 50;
				box.x = 50;
				box.y = py;
				parmData.box = box;
				box.addEventListener(MouseEvent.MOUSE_DOWN, onInputDown);
				container.addChild(box);
			}
			else
			{
				var input:TextInput = new TextInput;
				input.height = 20;
				input.width = 60;
				input.x = 50;
				input.y = py;
				if(type == "array_ccp" || type == "array_ccp_curve" )
				{
					input.prompt = name;
					input.addEventListener(MouseEvent.MOUSE_DOWN, onPathInputDown);
					parmData.path = new Array;
				}
				else
					input.addEventListener(MouseEvent.MOUSE_DOWN, onInputDown);
				parmData.input = input;
				container.addChild(input);
			}
			parmInput.push(parmData);
		}
		
		private function onInputDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		private function onPathInputDown(e:MouseEvent):void
		{
			e.stopPropagation();
			
			var name:String = TextInput(e.currentTarget).prompt;
			var data:Object = this.getParmData(name);
			
			var window:PathEditPanel = new PathEditPanel(name, data.path, data.type=="array_ccp_curve");
			window.addEventListener(MsgEvent.EDIT_PATH, onReturnPath);
			PopUpManager.addPopUp(window, this, true);
			PopUpManager.centerPopUp(window);
		}
		
		private function onReturnPath(e:MsgEvent):void
		{
			var data:Object = this.getParmData(e.hintMsg);
			TextInput(data.input).text = JSON.stringify(e.hintData);
			data.path = e.hintData;
			
		}
		
		private function getParmData(parmName:String):Object
		{
			for each(var p:Object in parmInput)
			{
				if(p.name == parmName)
				{
					return p;
				}
			}
			return null;
		}
		
		private function onLabelMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		
	}
}