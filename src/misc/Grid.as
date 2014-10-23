package misc
{
	import mx.core.UIComponent;
	
	public class Grid extends UIComponent
	{
		internal var _barWidth : Number = 20;
		internal var _value1 : Number = 50;
		
		public function Grid()
		{
			super();
		}
		
		public function get value1() : Number {
			return _value1;
		}
		
		public function set value1(value: Number) : void {
			this._value1 = value;
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
		
		override protected function measure() : void {
			measuredHeight    = _value1;
			measuredMinHeight = _value1;
			measuredWidth     = _barWidth;
			measuredMinWidth  = _barWidth;
			
		}
		
		override protected function updateDisplayList(
			unscaledWidth:Number, unscaledHeight:Number):void {
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			graphics.clear();
			graphics.lineStyle(1, 0x000000, 1.0);
			
			graphics.beginFill(0x00ff00, 1.0);
			
			graphics.drawRect(0, 0, 20, _value1);
			
		}
	}
}