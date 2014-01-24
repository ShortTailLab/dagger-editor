package behaviorEdit
{
	public class BNodeFactory
	{
		static var numCount:int = 0;
		
		static public function createBNode(type:String):BNode
		{
			var node:BNode = null;
			if(type == BType.BTYPE_BASIC)
				node = new BNode;
			else if(type == BType.BTYPE_SEQ)
				node = new SeqBNode;
			else if(type == BType.BTYPE_ROOT)
				node = new RootBNode;
			else if(type == BType.BTYPE_EXEC)
				node = new ExecBNode();
			else if(type == BType.BTYPE_PAR)
				node = new ParBNode;
			else if(type == BType.BTYPE_SEL)
				node = new SelBNode;
			else if(type == BType.BTYPE_COND)
				node = new CondBNode;
			else if(type == BType.BTYPE_LOOP)
				node = new LoopBNode;
			if(node)
				node.nodeId = numCount++;
			return node;
		}
	}
}