/**
 * Copyright 2010-2012 Singapore Management University
 * Developed under a grant from the Singapore-MIT GAMBIT Game Lab
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL was
 * not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
package sg.edu.smu.ksketch2.model.data_structures
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import sg.edu.smu.ksketch2.utils.iterators.INumberIterator;
	
	/**
	 * The ISpatialKeyFrame interface serves as the interface class that defines the core
	 * implementations of spatial key frames in K-Sketch. Spatial key frames contain
	 * spatial data such as its paths and transformation center.
	 */
	public interface ISpatialKeyFrame extends IKeyFrame
	{
		/**
		 * Dirties the key and all future keys, forcing recomputation of its matrix when it is required.
		 */
		function dirtyKey():void;
		
		/**
		 * Gets a clone of the key's transformation center.
		 * 
		 * @return A clone of the key's transformation center.
		 */
		function get center():Point;
		
		/**
		 * Gets the spatial key's matrix, concatenated with matrices of previous keys at the given time.
		 * 
		 * @param time The target time.
		 * @return The spatial key's full matrix.
		 */
		function fullMatrix(time:Number):Matrix;
		
		/**
		 * Gets the spatial key's own matrix up to the given time.
		 * 
		 * @param time The target time.
		 * @return The spatial key's partial matrix.
		 */
		function partialMatrix(time:Number):Matrix;
		
		/**
		 * Returns an iterator that gives the times of all translate events, in order from beginning to end. 
		 * If this key frame has no previous key frame, returns null.
		 * 
		 * @return An iterator for all transate event times.
		 */
		function translateTimeIterator():INumberIterator;
		
		/**
		 * Returns an iterator that gives the times of all rotate events, in order from beginning to end. 
		 * If this key frame has no previous key frame, returns null.
		 * 
		 * @return An iterator for all rotate event times.
		 */
		function rotateTimeIterator():INumberIterator;
		
		/**
		 * Returns an iterator that gives the times of all scale events, in order from beginning to end. 
		 * If this key frame has no previous key frame, returns null.
		 * 
		 * @return An iterator for all scale event times.
		 */
		function scaleTimeIterator():INumberIterator;		

	}
}