/**------------------------------------------------
* Copyright 2012 Singapore Management University
* All Rights Reserved
*
*-------------------------------------------------*/

package sg.edu.smu.ksketch.logger
{
	import sg.edu.smu.ksketch.model.geom.KPathPoint;

	public class KTransitionLog extends KInteractiveLog
	{
		private var _transitionType:String;
		
		public function KTransitionLog(transition:String, transitionType:String, 
									   cursorPath:Vector.<KPathPoint>)
		{
			super(cursorPath, transition);
			_transitionType = transitionType;
		}
		
		public function get transitionType():String
		{
			return _transitionType;
		}

		public function set transitionType(value:String):void
		{
			_transitionType = value;
		}

		public override function toXML():XML
		{
			var node:XML = super.toXML();
			node.@[KLogger.TRANSITION_TYPE] = _transitionType;
			return node;
		}
	}
}