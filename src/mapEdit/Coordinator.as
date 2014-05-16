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
		
		public function setMeshDensity( height:Number ):void
		{
			var width:Number = MainScene.kSCENE_WIDTH-90;
			
			this.mUnitWidth 	= 70;
			this.mUnitHeight 	= 100;
				
			this.mNumRows 		= int( height / this.mUnitHeight );
			this.mNumColums 	= int( width / this.mUnitWidth );
			this.mNumColums    /= 2;
			this.mUnitWidth 	= width/2 / this.mNumColums;
			
			this.mTickInterval 	= 80;
			
			this.removeChildren();
			
			var currHeight:Number = 0, i:int=0;
			this.graphics.clear();
//			this.graphics.lineStyle(2);
//			this.graphics.moveTo(0, currHeight);
			
//			this.mTickMarks = new Vector.<TextField>;	
//			var length:int = int(height/this.mTickInterval)+1;
//			for( i=0; i<length ; i++ )
//			{
//				currHeight += this.mTickInterval;
//			
//				if( i < length-1 )
//				{
//					this.graphics.lineTo(0, -currHeight);
//					this.graphics.lineTo(-5, -currHeight);
//					this.graphics.moveTo(0, -currHeight);
//					this.graphics.lineTo(0, -currHeight);
//				}
//			}
			
			if( !this.mShowGrid ) return;
			
//			this.graphics.lineStyle(1, 0, 0.3);
//			this.graphics.beginFill(0xffffff,0);
//			this.graphics.drawRect(0, -mNumRows*mUnitHeight, width/2, mNumRows*mUnitHeight);
//			this.graphics.endFill();
//			
			for(i = 0; i<this.mNumRows; i++)
			{
				this.graphics.moveTo(0, -i*mUnitHeight);
				this.graphics.lineTo(width/2, -i*mUnitHeight);
			}
			
			var boldLine:int = 1280;
			this.graphics.lineStyle(2);
			for(i=0; i<1; i++)
			{
				this.graphics.moveTo( 0, -boldLine/2 );
				this.graphics.lineTo(width/2, -boldLine/2);
				boldLine += 1280;
			}
			
			this.graphics.lineStyle(1.5, 0xFF4444 );
			boldLine = 1280;
			for(i=0; i<3; i++ )
			{
				this.graphics.moveTo( 0, -(boldLine-200)/2 );
				this.graphics.lineTo(width/2, -(boldLine-200)/2 );
				
				this.graphics.moveTo( 0, -(boldLine-800)/2 );
				this.graphics.lineTo(width/2, -(boldLine-800)/2 );
				boldLine += 1280;
			}			
			
//			for(i=0; i<
			
			this.graphics.lineStyle( 1, 0, 0.3 );
			
			for(var j:int = 0; j<this.mNumColums; j++)
			{
				this.graphics.moveTo(j*mUnitWidth, 0);
				this.graphics.lineTo(mUnitWidth*j, -this.mNumRows*this.mUnitHeight);
			}
			
		}
		
		public function getGridPos( srcX:Number = -1, srcY:Number = -1):Point
		{
			if( srcX==-1 ) srcX = this.mouseX;
			if( srcY==-1 ) srcY = this.mouseY;
			
			var row:int = -srcY / 640;

			var gX:int = (srcX+1)/(this.mUnitWidth*0.5);
			var gY:int = -(srcY-1)/(this.mUnitHeight);

			return new Point(Number(gX)*(this.mUnitWidth*0.5), -Number(gY)*(this.mUnitHeight));
		}
		
		public function getPos():Point
		{
			return new Point(this.mouseX, this.mouseY);
		}
	}
}