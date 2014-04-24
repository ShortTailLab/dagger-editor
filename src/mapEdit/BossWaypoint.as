package mapEdit
{
	import flash.display.Shape;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import spark.core.SpriteVisualElement;

	public class BossWaypoint extends Component
	{
		var mDot:SpriteVisualElement = null;
		var mText:TextField = null;
		var mFormat:TextFormat = null;
		var mIndex:int = -1;
		var mIsSelected = false;
		var mSelectionFrame = null;
		
		public function BossWaypoint(index)
		{
			super();
			
			this.mIndex = index;
			
			// dot
			var dot:SpriteVisualElement = new SpriteVisualElement;
			dot.graphics.lineStyle(1);
			dot.graphics.beginFill(128);
			dot.graphics.drawCircle(0, 0, 10);
			dot.graphics.endFill();
			this.mDot = dot;
			this.addChild(dot);
			
			// text field
			this.mText = new TextField();
			with(this.mText)
			{
				text = index;
				x = -6;
				y = -8;
				seletable = false;
			}
			this.addChild(this.mText);
			
			// font format
			this.mFormat = new TextFormat(null, 16);
			this.mFormat.color = 0xEEEEEE;
			this.mText.setTextFormat(this.mFormat);
			
			this.mSelectionFrame = new Shape;
			this.mSelectionFrame.graphics.lineStyle(1, 0xff0000);
			this.mSelectionFrame.graphics.drawRect(-10, -10, 20, 20);
			this.mSelectionFrame.visible = false;
			this.addChild( this.mSelectionFrame );
		}
		
		override public function select(value:Boolean):void 
		{
			this.mIsSelected = value;
			this.mSelectionFrame.visible = value;
		}
	}
}