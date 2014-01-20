package editEntity
{
	public class MatFactory
	{
		static public function createMat(type:String, textWidth:int = -1):EditBase
		{
			if(type == TriggerSprite.TRIGGER_TYPE)
				return new TriggerSprite;
			else
				return new MatSprite(type, -1, textWidth);
		}
	}
}