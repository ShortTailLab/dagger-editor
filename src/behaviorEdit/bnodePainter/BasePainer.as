package behaviorEdit.bnodePainter
{
	import behaviorEdit.bnodeController.BNodeController;

	public class BasePainer
	{
		protected var controller:BNodeController;
		
		public function BasePainer(ctrl:BNodeController)
		{
			controller = ctrl;
		
		}
		
		public function paint():void
		{
			
		}
		
	}
}