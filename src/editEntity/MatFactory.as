package editEntity
{
	public class MatFactory
	{
		static public function createMat(type:String, textWidth:int = -1):EditBase
		{
			if(type == TriggerSprite.TRIGGER_TYPE)
				return new TriggerSprite;
			else
				return new MatSprite(null, type, -1, textWidth);
		}
		
		static public function createMatOnView(editView:EditView, type:String, textWidth:int = -1):EditBase
		{
			if(type == TriggerSprite.TRIGGER_TYPE)
				return new TriggerSprite(editView);
			else
				return new MatSprite(editView, type, -1, textWidth);
		}
	}
}