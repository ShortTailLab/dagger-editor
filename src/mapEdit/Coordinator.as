package mapEdit
{
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import spark.core.SpriteVisualElement;
	
	public class Coordinator extends SpriteVisualElement
	{
		private var mTickMarks:Vector.<TextField>;
		private var mTickInterval:Number = 0;
		
		private var mUnitHeight:Number;
		private var mUnitWidth:Number;
		
		private var mNumColums:int = 0;
		private var mNumRows:int = 0;
		private var mShowGrid:Boolean = true;
		
		public function Coordinator() {}
		
		public function showGrid( v:Boolean ):void {
			this.mShowGrid = v;
		}
		
		public function setMeshDensity( unitWidth:int, unitHeight:int, height:Number, base:Number ):void
		{
			
			this.mUnitWidth 	= unitWidth;
			this.mUnitHeight 	= unitHeight;
			
			this.mNumRows 		= int(height / unitHeight);
			this.mNumColums 	= int( MainScene.kSCENE_WIDTH / unitWidth );
			this.mNumColums    /= 2;
			this.mUnitWidth 	= MainScene.kSCENE_WIDTH/2 / this.mNumColums;
			
			this.mTickInterval 	= height / (this.mNumRows/5);
			
			this.removeChildren();
			
			var currHeight:Number = 0;
			this.graphics.clear();
			this.graphics.lineStyle(2);
			this.graphics.moveTo(0, currHeight);
			
			this.mTickMarks = new Vector.<TextField>;	
			var length:int = int(height/this.mTickInterval)+1;
			for( var i:int=0; i<length ; i++ )
			{
				var mark:TextField = new TextField();
				with( mark ) {
					x = -35; y = -currHeight-15; width = 60; 
					text =  String(2*int(base+currHeight));
				}
				mark.defaultTextFormat = new TextFormat(null, 20);
				
				currHeight += this.mTickInterval;
				
				this.addChild( mark );
				this.mTickMarks.push( mark );
			
				if( i < length-1 )
				{
					this.graphics.lineTo(0, -currHeight);
					this.graphics.lineTo(-5, -currHeight);
					this.graphics.moveTo(0, -currHeight);
					this.graphics.lineTo(0, -currHeight);
				}
			}
			
			if( !this.mShowGrid ) return;
			
			this.graphics.lineStyle(1, 0, 0.3);
			this.graphics.beginFill(0xffffff,0);
			this.graphics.drawRect(0, -mNumRows*mUnitHeight, MainScene.kSCENE_WIDTH/2, mNumRows*mUnitHeight);
			this.graphics.endFill();
			
			for(i = 0; i<this.mNumRows; i++)
			{
				this.graphics.moveTo(0, -i*mUnitHeight);
				this.graphics.lineTo(MainScene.kSCENE_WIDTH/2, -i*mUnitHeight);
			}
			
			for(var j:int = 0; j<this.mNumColums; j++)
			{
				this.graphics.moveTo(j*mUnitWidth, 0);
				this.graphics.lineTo(mUnitWidth*j, -i*mUnitHeight);
			}
			
		}
		
		public function getGridPos(x:int, y:int):Point
		{
			var gX:int = x/mUnitWidth;
			var gY:int = -y/mUnitHeight;
			if(gX>=0 && gX<=mNumColums && gY>=0 && gY<=mNumRows)
				return new Point(gX*mUnitWidth+mUnitWidth*0.5, gY*mUnitHeight);
			return null;
		}
	
//		private function onMouseDown(e:MouseEvent):void
//		{
//			isClick = true;
//		}
//		
//		private function onMouseMove(e:MouseEvent):void
//		{
//			isClick = false;
//		}
//		private function onMouseUp(e:MouseEvent):void
//		{
//			if(isClick)
//			{
//				var gX:int = e.localX/mUnitWidth;
//				var gY:int = -e.localY/mUnitHeight;
//				if(gX>=0 && gX<=mNumColums && gY>=0 && gY<=mNumRows)
//				{
//					var evt:TimeLineEvent = new TimeLineEvent("gridClick");
//					evt.data.x = gX*mUnitWidth+mUnitWidth*0.5;
//					evt.data.y = gY*mUnitHeight;
//					this.dispatchEvent(evt);
//				}
//				isClick = false;
//			}
//		}
	}
}