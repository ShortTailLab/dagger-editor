package excel
{
	public class Grid
	{
		var mWidth = 0;
		var mHeight = 0;
		
		var mRowList = null;
		
		public function Grid(width:int, height:int)
		{
			mWidth = width;
			mHeight = height;
			
			// create an empty grid
			mRowList = new Array(mHeight);
			for(var i:int=0; i<mHeight; i++)
				mRowList[i] = new Array(mWidth);
		}
		
		public function e(x:int, y:int) : *
		{
			return mRowList[y][x];
		}
		
		public function get width():int { return mWidth; }
		public function get height():int {  return mHeight; }
		
		public function se(x:int, y:int, val:*):void
		{
			mRowList[y][x] = val;
		}
		
		public function col(x:int):Array
		{
			var col:Array = new Array(mHeight);
			for(var i:int=0; i<mHeight; i++)
			{
				col[i] = mRowList[i][x];
			}
			return col;
		}
		
		public function row(y:int):Array
		{
			// create a copy
			return mRowList[y].concat();
		}
	}
}