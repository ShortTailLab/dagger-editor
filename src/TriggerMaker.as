package
{
	
	import flash.events.MouseEvent;
	
	import editEntity.TriggerSprite;

	public class TriggerMaker
	{
		private var target:TriggerSprite = null;
		private var view:EditView = null;
		
		public function TriggerMaker(triSprite:TriggerSprite, _view:EditView)
		{
			target = triSprite;
			view = _view;
			
			target.beginTriDot.addEventListener(MouseEvent.MOUSE_DOWN, onPointMouseDown);
			view.addEventListener(MouseEvent.MOUSE_MOVE, onViewMouseMove);
			view.addEventListener(MouseEvent.MOUSE_UP, onViewMouseUp);
		}
		
		private var isDrawing:Boolean = false;
		private function onPointMouseDown(e:MouseEvent):void
		{
			isDrawing = true;
		}
		
		private function onViewMouseMove(e:MouseEvent):void
		{
			
		}
		private function onViewMouseUp(e:MouseEvent):void
		{
			
		}
		
	}
}