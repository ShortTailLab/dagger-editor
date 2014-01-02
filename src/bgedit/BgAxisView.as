package bgedit
{
	import mx.core.UIComponent;

	public class BgAxisView extends UIComponent
	{
		public function BgAxisView( horizontal:Boolean, min:Number, max:Number )
		{
			_horizontal = horizontal;
			_min = min;
			_max = max;
			
			draw();
		}
		
		private function draw():void {
			
		}
		
		private var _horizontal:Boolean;
		private var _min:Number;
		private var _max:Number;
	}
}