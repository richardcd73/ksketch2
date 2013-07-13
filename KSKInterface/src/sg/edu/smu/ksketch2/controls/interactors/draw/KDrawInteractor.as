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
	import sg.edu.smu.ksketch2.model.data_structures.KModelObjectList;
	import sg.edu.smu.ksketch2.model.objects.KStroke;
	import sg.edu.smu.ksketch2.operators.operations.KCompositeOperation;
	import sg.edu.smu.ksketch2.utils.KSelection;
	import sg.edu.smu.ksketch2.canvas.components.view.objects.KStrokeView;
	
	import spark.core.SpriteVisualElement;

	/**
	 * The KDrawInteractor object handles the drawing interaction of the K-Sketch interface.
	 */
	public class KDrawInteractor extends KInteractor
	{
		public static var penColor:uint = 0X000000;				// default pen color
		public static var penThickness:Number = 3.5;			// default pen thickness
		private var _temporaryStroke:KStrokeView;				// default temporary stroke
		private var _points:Vector.<Point>;						// list of points drawn
		protected var _interactorDisplay:SpriteVisualElement;	// interactor display
		
		/**
		 * Constructs the KDrawInteractor object.
		 * 
		 * @param KSketchInstance The instance of the sketch.
		 * @param interactorDisplay The interactor display.
		 * @param interactionControl The interaction control.
		 */
		public function KDrawInteractor(KSKetchInstance:KSketch2,
										interactorDisplay:SpriteVisualElement,
										interactionControl:IInteractionControl)
		{
			// set the current interactor display
			_interactorDisplay = interactorDisplay;
			
			// set the current sketch and interaction control
			super(KSKetchInstance, interactionControl);
			
			// create the temporary stroke
			_temporaryStroke = new KStrokeView(null);
		}
		
		/**
		 * DrawInteractor.interaction_Begin creates a temporary view to display the
		 * new stroke that is being drawn. This temporaray view has no properties and
		 * is seriously just there for cosmetic purposes.
		 * 
		 * @param point The current point in the temporary stroke.
		 */
		override public function interaction_Begin(point:Point):void
		{
			// indicate the start of the interaction control (i.e., appears to consist of doing nothing)
			_interactionControl.begin_interaction_operation();
			
			// activate the drawing interactor by setting the temporary stroke's properties
			// and adding the first point of the stroke to the interactor display 
			activate();
			
			// update the list of points added
			interaction_Update(point);
		}
		
		/**
		 * Updates the temporary view with the new mouse move point.
		 * Adds to the collection of points that will be used to create the
		 * Stroke Object in the model
		 * 
		 * @param point The current point in the temporary stroke.
		 */
		override public function interaction_Update(point:Point):void
		{
			// add the latest point to the temporary stroke
			_temporaryStroke.edit_AddPoint(point);
		}
		
		/**
		 * Handles the end of the drawing interaction.
		 */
		override public function interaction_End():void
		{
			// case: naively removes possible unintentional "hooks" of drawn strokes with length less than 2 points
			if(_points.length < 2)
			{
				// remove the existing temporary stroke
				reset();
				
				// indicate the end of the interaction control
				_interactionControl.end_interaction_operation();
				
				// end the drawing interaction as if nothing happened
				return;
			}
			
			// create the associating variables
			// 1. create a composite operation
			// 2. set the temporary stroke to the new stroke
			// 3. create a new model object list
			var drawOp:KCompositeOperation = new KCompositeOperation();
			var newStroke:KStroke = _KSketch.object_Add_Stroke(_points, _KSketch.time, penColor, penThickness, drawOp);
			var newObjects:KModelObjectList = new KModelObjectList();
			
			// add the new stroke to the model object list
			newObjects.add(newStroke);
			
			// indicate the end of the interaction control with the associating drawing operation and selected stroke
			// note: this is where the stroke is added to the interface
			_interactionControl.end_interaction_operation(drawOp, new KSelection(newObjects));
			
			// remove the existing temporary stroke
			reset();
		}
		
		/**
		 * Activiates the draw interactor by adding a newly-created temporary stroke.
		 */
		override public function activate():void
		{
			_points = new Vector.<Point>();					// create a new list of points
			_temporaryStroke.points = _points;				// initialize the temporary stroke's points to the new list
			_temporaryStroke.color = penColor;				// set the default color of the temporary stroke
			_temporaryStroke.thickness = penThickness;		// set the default pen thickness of the temporary stroke
			_interactorDisplay.addChild(_temporaryStroke);	// add the temporary stroke to the interactor display
		}
		
		/**
		 * Resets the draw interactor by removing the existing temporary stroke.
		 */
		override public function reset():void
		{
			// case: removes the temporary stroke with an existing parent
			if(_temporaryStroke.parent)
				_temporaryStroke.parent.removeChild(_temporaryStroke);
		}
	}
}