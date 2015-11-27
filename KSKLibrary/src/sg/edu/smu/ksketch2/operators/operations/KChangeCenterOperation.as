/**
 * Copyright 2010-2015 Singapore Management University
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL was
 * not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
package sg.edu.smu.ksketch2.operators.operations
{
	import flash.geom.Point;
	
	import sg.edu.smu.ksketch2.model.objects.KGroup;
	import sg.edu.smu.ksketch2.model.objects.KObject;
	
	import sg.edu.smu.ksketch2.KSketch2;

	/**
	 * The KChangeCenterOperation class serves as the concrete class for
	 * handling change center operations in K-Sketch.
	 */
	public class KChangeCenterOperation implements IModelOperation
	{
		private var _object:KObject;		// the current object
		private var _oldCenter:Point;		// the older center
		private var _newCenter:Point;		// the newer center
		
		/**
		 * The main constructor for the KChangeCenterOperation class.
		 * 
		 * @param object The target current object.
		 * @param oldCenter The target older center.
		 * @param newCenter The target newer center.
		 */
		public function KChangeCenterOperation(object:KObject, oldCenter:Point, newCenter:Point)
		{
			_object = object;			// set the current object
			_oldCenter = oldCenter;		// set the older center
			_newCenter = newCenter;		// set the newer center
		
			/*var log:XML = <op/>;
			log.@type = "Change Center";
			log.@oldCenter = _oldCenter.toString();
			log.@newCenter = _newCenter.toString();
			log.appendChild(_object.serialize());
			KSketch2.log.appendChild(log);*/
		}
		
		/**
		 * Gets the error message for the change center operation.
		 * 
		 * @return The error message for the change center operation.
		 */
		public function get errorMessage():String
		{
			// handle null object cases
			if(!_object)
				return "The target object wasn't specified";
			
			// handle null older center cases
			if(!_oldCenter)
				return "The old center wasn't specified";
			
			// handle null newer center cases
			if(!_newCenter)
				return "The new center wasn't specified";
			
			// handle any other kind of error cases
			return "There is an error with change center operation";
		}
		
		/**
		 * Checks whether the change center operation is valid. If not, it
		 * should fail on construction and not be added to the operation stack.
		 * 
		 * @return Whether the change center operation is valid.
		 */
		public function isValid():Boolean
		{
			return 	(_object != null) &&		// check if the current object is non-null
					(_oldCenter != null) &&		// check if the older center is non-null
					(_newCenter != null);		// check if the newer center is non-null
		}
		
		/**
		 * Undoes the change center operation by reverting the state of the
		 * model to immediately before the change center operation was performed.
		 */
		public function undo():void
		{
			// set the object's current center to the older center
			_object.center = _oldCenter;
		}
		
		/**
		 * Redoes the change center operation by reverting the state of the
		 * model to immediately after the change center operation was performed.
		 */
		public function redo():void
		{
			// set the object's current center to the newer center
			_object.center = _newCenter;
		}
		
		/**
		 * Debugs the change center operation by showing what is inside the
		 * operation.
		 */
		public function debug():void
		{
			
		}
	}
}