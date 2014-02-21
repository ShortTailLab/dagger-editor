package
{
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	
	public class XMLDisplayer extends UIComponent
	{
		public var labelField:String = "";
		private var _dataProvider:XML = null;
		
		public function XMLDisplayer()
		{
			super();
		}
		
		public function get dataProvider():XML
		{
			return _dataProvider;
		}

		public function set dataProvider(value:XML):void
		{
			_dataProvider = value;
		}
		
		private function update():void
		{
			
		}
		
		public function display():void
		{
			if(this.dataProvider)
			{
				displayXML(this.dataProvider, new Rectangle(0, 0, this.width, 20), true);
			}
		}

		private function displayXML(xml:XML, posRect:Rectangle, ignoreCurr:Boolean = false):DisplayBar
		{
			var childPosRect:Rectangle = posRect.clone();
			var bar:DisplayBar = null;
			if(!ignoreCurr)
			{
				bar = new DisplayBar(posRect.width);
				bar.setLabel(xml.attribute(labelField));
				bar.x = posRect.x;
				bar.y = posRect.y;
				this.addChild(bar);
				
				var childPadding:int = posRect.height;
				childPosRect.x += childPadding;
				childPosRect.y += childPadding;
				childPosRect.width -= childPadding;
			}
			
			if(childPosRect.width > 0)
			{
				for each(var childXML:XML in xml.children())
				{
					displayXML(childXML, childPosRect);
					childPosRect = childPosRect.clone();
					childPosRect.y += posRect.height;
				}
			}
			return bar;
		}
	}
}
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;

import mx.core.UIComponent;

class DisplayerEvent extends Event
{
	public function DisplayerEvent(type:String)
	{
		super(type);
	}
}

class DisplayBarType
{
	static public var PARENT:String = "parent";
	static public var CHILD:String = "child";
}

class DisplayBar extends UIComponent
{
	public var barType:String = "";
	public var boundingBox:Rectangle = null;
	
	private var label:TextField = null;
	private var barHeight:int = 20;
	private var expandBtn:UIComponent = null;
	private var color:uint;
	private var bg:UIComponent = null;
	private var bgFrame:UIComponent = null;
	
	public function DisplayBar(w:int, h:int = 20, _color:uint = 0xffffff)
	{
		this.color = _color;
		this.barHeight = h;
		bg = new UIComponent;
		bg.graphics.beginFill(color);
		bg.graphics.drawRect(0, 0, w, barHeight);
		bg.graphics.endFill();
		this.addChild(bg);
		bgFrame = new UIComponent;
		bgFrame.graphics.lineStyle(1, 0.7);
		bgFrame.graphics.drawRect(0, 0, w, barHeight);
		this.addChild(bgFrame);
		
		label = new TextField;
		label.selectable = false;
		label.defaultTextFormat = new TextFormat(null, 14);
		label.width = w-barHeight;
		label.height = barHeight;
		label.x = barHeight;
		this.addChild(label);
		
		boundingBox = new Rectangle(0, 0, w, barHeight);
		this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	public function setType(type:String):void
	{
		if(type == DisplayBarType.PARENT && !expandBtn)
		{
			expandBtn = makeExpandBtn();
			expandBtn.x = 0;
			expandBtn.y = barHeight*0.5;
			this.addChild(expandBtn);
		}
		else if(type == DisplayBarType.CHILD && expandBtn)
		{
			this.removeChild(expandBtn);
			expandBtn = null;
		}
		this.barType = type;
	}
	
	public function setLabel(val:String):void
	{
		label.text = val;
	}
	
	public function select():void
	{
		this.setColor(0x1E90FF);
	}
	
	public function unselect():void
	{
		this.setColor(color);
	}
	
	private function onMouseOver(e:MouseEvent):void
	{
		this.setColor(0x999999);
	}
	
	private function onMouseOut(e:MouseEvent):void
	{
		this.setColor(this.color);
	}
	
	private function setColor(color:uint):void
	{
		var colorTF:ColorTransform = new ColorTransform;
		colorTF.color = color;
		bg.transform.colorTransform = colorTF;
	}
	
	private function makeExpandBtn():UIComponent
	{
		var triLength:int = barHeight*0.6;
		var btn:UIComponent = new UIComponent;
		btn.graphics.lineStyle(1);
		btn.graphics.beginFill(0x999999);
		btn.graphics.moveTo(0, -triLength*0.5);
		btn.graphics.lineTo(triLength*Math.sqrt(3)*0.5, 0);
		btn.graphics.lineTo(0, triLength*0.5);
		btn.graphics.lineTo(0, -triLength*0.5);
		return btn;
	}
}


