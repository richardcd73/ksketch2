/**
 * Copyright 2010-2012 Singapore Management University
 * Developed under a grant from the Singapore-MIT GAMBIT Game Lab
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL was
 * not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
package sg.edu.smu.ksketch2.controls.interactors.draw
{
	import flash.geom.Point;
	
	import sg.edu.smu.ksketch2.KSketch2;
	import sg.edu.smu.ksketch2.canvas.controls.IInteractionControl;
	import sg.edu.smu.ksketch2.operators.operations.KCompositeOperation;
	import sg.edu.smu.ksketch2.canvas.components.view.objects.IObjectView;
	import sg.edu.smu.ksketch2.canvas.components.view.KModelDisplay;
	import sg.edu.smu.ksketch2.canvas.components.view.objects.KObjectView;
	
	/**
	 * The KEraserInteractor object handles the erasing interaction of the K-Sketch interface.
	 */
	public class KEraserInteractor extends KInteractor
	{
		private var _currentOperation:KCompositeOperation;	// the current operation
		private var _modelDisplay:KModelDisplay;			// the model display
		private var _startPoint:Point;						// the starting point
		private var _currentPoint:Point;					// the current point
		
		/**
		 * Constructs the KEraserInteractor object.
		 * 
		 * @param KSketchInstance The current sketch.
		 * @param interactionControl The interaction control.
		 * @param modelDisplay The model display.
		 */
		public function KEraserInteractor(KSketchInstance:KSketch2,
										  interactionControl:IInteractionControl,
										  modelDisplay:KModelDisplay)
		{
			// set the current sketch and interaction control
			super(KSketchInstance, interactionControl);
			
			// set the model display
			_modelDisplay = modelDisplay;
		}
		
		/**
		 * Begins the interaction by initializing the interaction control and current operation.
		 * 
		 * @param point A dummy point.
		 */
		override public function interaction_Begin(point:Point):void
		{
			// indicate the start of the interaction control (i.e., appears to consist of doing nothing)
			_interactionControl.begin_interaction_operation();
			
			// initialize the current operation
			_currentOperation = new KCompositeOperation();
		}
		
		/**
		 * ???.
		 * 
		 * @param point
		 */
		override public function interaction_Update(point:Point):void
		{
			// ???
			var view:IObjectView;
			
			// ???
			point = _modelDisplay.localToGlobal(point);
			
			// ???
			for each (view in _modelDisplay.viewsTable)
			{
				// ???
				if((view as KObjectView).alpha > 0)
				{
					(view as KObjectView).eraseIfHit(point.x, point.y, _KSketch.time, _currentOperation);
				}
			}
		}
		
		/**
		 * ...
		 */
		override public function interaction_End():void
		{
			if(_currentOperation.length == 0)
				_interactionControl.end_interaction_operation();
			else
				_interactionControl.end_interaction_operation(_currentOperation, null);
		}
	}
}