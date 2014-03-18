package mapEdit
{
	public class MatFactory
	{
		static public function createMat(type:String, textWidth:int = -1):Component
		{
			if(type == AreaTriggerComponent.TRIGGER_TYPE)
				return new AreaTriggerComponent;
			else
				return new EntityComponent(null, type, -1, textWidth);
		}
		
		static public function createMatOnView(editView:EditView, type:String, textWidth:int = -1):Component
		{
			if(type == AreaTriggerComponent.TRIGGER_TYPE)
				return new AreaTriggerComponent(editView);
			else
				return new EntityComponent(editView, type, -1, textWidth);
		}
	}
}