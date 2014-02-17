package behaviorEdit.bnodeController
{
	import behaviorEdit.BType;
	import behaviorEdit.ParBNode;
	import behaviorEdit.bnodePainter.BNodePainter;
	import behaviorEdit.bnodePainter.ParGraphPainter;
	import behaviorEdit.bnodePainter.SeqGraphPainter;

	public class BTNodeCtrlFactory
	{
		public function BTNodeCtrlFactory()
		{
		}
		
		static public function getController(type:String):BNodeController
		{
			var ctrl:BNodeController = new BNodeController;
			ctrl.type = type;
			if(type == BType.BTYPE_SEQ)
			{
				ctrl.color = 0xA020F0;
				ctrl.nodePainter = new BNodePainter(ctrl);
				ctrl.graphPainter = new SeqGraphPainter(ctrl)
			}
			else if(type == BType.BTYPE_SEL)
			{
				ctrl.color = 0xD15FEE;
				ctrl.nodePainter = new BNodePainter(ctrl);
				ctrl.graphPainter = new SeqGraphPainter(ctrl);
			}
			else if(type == BType.BTYPE_PAR)
			{
				ctrl.color = 0xF4A460;
				ctrl.nodePainter = new BNodePainter(ctrl);
				ctrl.graphPainter = new ParGraphPainter(ctrl);
			}
			else if(type == BType.BTYPE_ROOT)
			{
				ctrl.color = 0x228B22;
				ctrl.nodePainter = new BNodePainter(ctrl);
				ctrl.graphPainter = new SeqGraphPainter(ctrl);
			}
			
			
			return ctrl;
		}
	}
}