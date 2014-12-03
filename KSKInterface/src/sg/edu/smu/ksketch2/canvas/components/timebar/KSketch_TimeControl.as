/**
 * Copyright 2010-2012 Singapore Management University
 * Developed under a grant from the Singapore-MIT GAMBIT Game Lab
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL was
 * not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
package sg.edu.smu.ksketch2.canvas.components.timebar
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.events.FlexEvent;
	
	import sg.edu.smu.ksketch2.KSketch2;
	import sg.edu.smu.ksketch2.canvas.components.popup.KSketch_Timebar_ContextMenu;
	import sg.edu.smu.ksketch2.canvas.components.popup.KSketch_Timebar_Context_Magnifier;
	import sg.edu.smu.ksketch2.canvas.components.popup.KSketch_Timebar_Magnifier;
	import sg.edu.smu.ksketch2.canvas.components.view.KSketch_CanvasView;
	import sg.edu.smu.ksketch2.canvas.controls.interactors.widgetstates.KWidgetInteractorManager;
	import sg.edu.smu.ksketch2.events.KTimeChangedEvent;
	
	public class KSketch_TimeControl extends KSketch_TimeSlider implements ITimeControl
	{
		public static const PLAY_START:String = "Start Playing";
		public static const PLAY_STOP:String = "Stop Playing";
		public static const RECORD_START:String = "Start Recording";
		public static const RECORD_STOP:String = "Stop Recording";
		public static const EVENT_POSITION_CHANGED:String = "position changed";

		public static const TIMEBAR_LIMIT:int = -10;
		public static const SNAP_DOWN:int = 20;
		public static const SNAP_MOVE:int = 20;
		
		public static const BAR_TOP:int = 0;
		public static const BAR_BOTTOM:int = 1;
		
		public static const DEFAULT_MAX_TIME:Number = 5000;
		public static const TIME_EXTENSION:Number = 5000;
		public static var recordingSpeed:Number = 1;
		
		public var action:String = "";
		public var recordingSpeed:Number = 1;
		private var _editMarkers:Boolean;
		
		public static const PLAY_ALLOWANCE:int = 2000;
		public static const MAX_ALLOWED_TIME:Number = 600000; //Max allowed time of 10 mins
		
		protected var _KSketch:KSketch2;
		protected var _tickmarkControl:KSketch_TickMark_Control;
		protected var _transitionHelper:KWidgetInteractorManager;
		protected var _magnifier:KSketch_Timebar_Magnifier;
		protected var _keyMenu:KSketch_Timebar_ContextMenu;
		protected var _keyMagnifier:KSketch_Timebar_Context_Magnifier;
		
		public static var _isPlaying:Boolean = false;
		protected var _timer:Timer;
		protected var _maxPlayTime:Number;
		protected var _rewindToTime:Number;
		private var _position:int;
		
		private var _maxFrame:int;
		private var _currentFrame:int;
		
		public var timings:Vector.<Number>;
		
		private var _touchStage:Point = new Point(0,0);
		private var _substantialMovement:Boolean = false;
		
		private var grabbedTickTimer:Timer;
		private var grabbedTickIndex:int;
		private var nearTick: Number;
		private var isNearTick: Boolean = false;
		private var moveTick:Boolean = false;
		
		private var showMagnifier:Boolean = false;
		private var _doubleClickTimer:Timer;
		
		private var DOUBLE_CLICK_SPEED:int = 250;
		private var mouseTimeout = "undefined";
		private var longTapTimer:Timer;
		private var longTap:Boolean = false;
		
		public function KSketch_TimeControl()
		{
			super();
		}
		
		public function init(KSketchInstance:KSketch2, tickmarkControl:KSketch_TickMark_Control,
							 transitionHelper:KWidgetInteractorManager,
							 magnifier:KSketch_Timebar_Magnifier, keyMenu:KSketch_Timebar_ContextMenu, 
							 keyMagnifier:KSketch_Timebar_Context_Magnifier):void
		{

			_KSketch = KSketchInstance;
			_tickmarkControl = tickmarkControl;
			_transitionHelper = transitionHelper;
			_magnifier = magnifier;
			_keyMenu = keyMenu;
			_keyMagnifier = keyMagnifier;
			timeLabels.init(this);
			
			_timer = new Timer(KSketch2.ANIMATION_INTERVAL);
			
			contentGroup.doubleClickEnabled = true;
			contentGroup.mouseEnabled = true;
			contentGroup.addEventListener(MouseEvent.MOUSE_DOWN, downTap);
			contentGroup.addEventListener(MouseEvent.CLICK, _handleTap, false, 0, true);
			contentGroup.addEventListener(MouseEvent.DOUBLE_CLICK, _handleTap, false, 0, true);
			
			maximum = KSketch_TimeControl.DEFAULT_MAX_TIME;
			time = 0;

			_position = BAR_TOP;
			dispatchEvent(new Event(EVENT_POSITION_CHANGED));
		}
		
		public function reset():void
		{
			maximum = KSketch_TimeControl.DEFAULT_MAX_TIME;
			time = 0;
		}
		
		public function get position():int
		{
			return _position;
		}
		
		/**
		 * Sets the position of the time bar
		 * Either KSketch_TimeControl.BAR_TOP for top
		 * KSketch_TimeControl.BAR_BOTTOM for bottom
		 */
		public function set position(value:int):void
		{
			if(value == _position)
				return;
			
			_position = value;
			
			if(_position == BAR_TOP)
			{
				removeElement(timeLabels);
				addElementAt(timeLabels,1);
			}
			else
			{
				removeElement(timeLabels);
				addElementAt(timeLabels,1);
			}
			
			_magnifier.dispatchEvent(new FlexEvent(FlexEvent.UPDATE_COMPLETE));
		}
		
		/**
		 * Maximum time value for this application in milliseconds
		 */
		public function set maximum(value:Number):void
		{
			var newVal:int = Math.ceil(value/1000) * 1000;
			_maxFrame = newVal/KSketch2.ANIMATION_INTERVAL;
			dispatchEvent(new Event(KTimeChangedEvent.EVENT_MAX_TIME_CHANGED));
		}
		
		/**
		 * Maximum time value for this application in milliseconds
		 */
		public function get maximum():Number
		{
			return _maxFrame * KSketch2.ANIMATION_INTERVAL;
		}
		
		/**
		 * Current time value for this application in milliseconds
		 */
		public function set time(value:Number):void
		{
			if(value < 0)
				value = 0;
			if(MAX_ALLOWED_TIME < value)
				value = MAX_ALLOWED_TIME;
			if(maximum < value)
				maximum = value;
			
			_currentFrame = timeToFrame(value);
			
			_KSketch.time = _currentFrame * KSketch2.ANIMATION_INTERVAL;
			
			if(KSketch_TimeControl.DEFAULT_MAX_TIME < time)
			{
				var modelMax:int = _KSketch.maxTime
					
				if(modelMax <= time && time <= maximum )
						maximum = time;
				else
					maximum = modelMax;
			}
			else if(time < KSketch_TimeControl.DEFAULT_MAX_TIME && maximum != KSketch_TimeControl.DEFAULT_MAX_TIME)
			{
				if(_KSketch.maxTime < KSketch_TimeControl.DEFAULT_MAX_TIME)
					maximum = KSketch_TimeControl.DEFAULT_MAX_TIME;
			}
			
			_magnifier.showTime(toTimeCode(time), _currentFrame, timeToX(time));
		}
		
		/**
		 * Current time value for this application in second
		 */
		public function get time():Number
		{
			return _KSketch.time
		}
		
		public function get currentFrame():int
		{
			return _currentFrame;
		}
		
		/**
		 * On touch function. Time slider interactions begins here
		 * Determines whether to use the tick mark control or to just itneract with the slider
		 */
		public function downTap(event:MouseEvent):void
		{
			longTap = false;
			
			if(!longTapTimer)
			{
				longTapTimer = new Timer(500,1);
				longTapTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _longTap);
				longTapTimer.start();
			}
			
			if(_isPlaying)
				stop();
			
			//start grabbedTickTimer to time how long the touchdown is
			//if timer completes (means longPress), grab the tick at that particular time
			grabbedTickTimer = new Timer(500,1);
			grabbedTickTimer.start();
			grabbedTickTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _grabTickOnLongTouch);
			
			_touchStage.x = event.stageX;
			_touchStage.y = event.stageY;
			_substantialMovement = false;
			
			var xPos:Number = contentGroup.globalToLocal(_touchStage).x;
			var dx:Number = Math.abs(xPos - timeToX(time));
			
			//check if position x is a tick
			var xPosIsTick:Boolean = false;
			if(_tickmarkControl._ticks)
			{
				var i:int;
				var roundXPos:Number = roundToNearestTenth(xPos);
				for(i=0; i<_tickmarkControl._ticks.length; i++)
				{
					if(roundXPos == _tickmarkControl._ticks[i].x)
					{
						xPosIsTick = true;
						nearTick = roundXPos;
						break;
					}
				}
				
				//implement autosnapping if xpos is not yet a tick
				if(!xPosIsTick)
				{
					for(i=0; i<_tickmarkControl._ticks.length; i++)
					{
						var tempTick:Number = _tickmarkControl._ticks[i].x;
						if(Math.round(xPos) >= (Math.round(tempTick) - SNAP_DOWN) && Math.round(xPos) <= (Math.round(tempTick) + SNAP_DOWN))
						{
							xPosIsTick = true;
							nearTick = tempTick;
							break;
						}
					}	
				}
			}
			
			//check if slider is on top if xPosIsTick is true
			if(xPosIsTick)
			{
				if(!KSketch_CanvasView.isWebViewer)
					_tickmarkControl.grabTick(nearTick);
				_autoSnap(nearTick);
				nearTick = 0;
			}
			else
				_autoSnap(xPos);
			
			if(_keyMenu.isOpen || _keyMagnifier.isOpen)
				_endTap(event);
		}
		
		private function _longTap(event:TimerEvent):void
		{
			longTap = true;
			longTapTimer.stop();
			longTapTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, _longTap);
			
			contentGroup.removeEventListener(MouseEvent.MOUSE_DOWN, downTap);
			contentGroup.removeEventListener(MouseEvent.CLICK, _handleTap);
			contentGroup.removeEventListener(MouseEvent.DOUBLE_CLICK, _handleTap);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, _moveTap);
			stage.addEventListener(MouseEvent.MOUSE_UP, _endTap);
		}
		
		/**
		 * Update time control interaction
		 */
		private function _moveTap(event:MouseEvent):void
		{
			action = "Move time slider on Time Bar";
			
			KSketch_CanvasView.tracker.trackPageview( "/timebar/moveTime" );
			
			//remove grabbed tick timer if it hasn't completed countdown when user enters move
			if(grabbedTickTimer.currentCount == 0)
			{
				grabbedTickTimer.removeEventListener(TimerEvent.TIMER, _grabTickOnLongTouch);
				grabbedTickTimer.stop();
			}
			
			//Only consider a move if a significant dx has been covered
			if(Math.abs(event.stageX - _touchStage.x) < (pixelPerFrame*0.5))
				return;
			
			_touchStage.x = event.stageX;
			_touchStage.y = event.stageY;
			_substantialMovement = true;
			
			var xPos:Number = contentGroup.globalToLocal(_touchStage).x;
			var i:int;
			
			if(_tickmarkControl._ticks)
			{
				for(i=0; i<_tickmarkControl._ticks.length; i++)
				{
					nearTick = _tickmarkControl._ticks[i].x;
					if(Math.floor(xPos) >= (Math.round(nearTick) - SNAP_MOVE) && Math.floor(xPos) <= (Math.round(nearTick) + SNAP_MOVE))
					{
						isNearTick = true;
						break;
					}
					else
						isNearTick = false;
				}
			}
			
			//Rout interaction into the tick mark control if there is a grabbed tick
			if(!KSketch_CanvasView.isPlayer && (_tickmarkControl.grabbedTick))
			{
				var oldXPos:Number;
				
				xPos = roundToNearestTenth(xPos);
				_tickmarkControl.move_markers(xPos);
				
				//If tickmark moves to the left and causes stacking of previous keyframes
				if(_tickmarkControl.moveLeft)
				{
					var length:int = _tickmarkControl._ticks.length;
					for(i=0; i<length; i++)
					{
						//get hold of the grabbed tick mark index first
						if(!grabbedTickIndex)
						{
							if(_tickmarkControl.grabbedTick.x == _tickmarkControl._ticks[i].x)
								grabbedTickIndex = i;
						}
						
						if(grabbedTickIndex)
						{
							//to prevent grabbing of near tick marks when stacking occurs, 
							//reposition xPos to the initial grabbed tick mark's x pos 
							if(i != grabbedTickIndex)
							{
								if(xPos == _tickmarkControl._ticks[i].x)
									xPos = _tickmarkControl._ticks[grabbedTickIndex].x;
							}
							else
								oldXPos = _tickmarkControl._ticks[i].x;
						}
					}
				}
				
				//if there is already a grabbed tick and xPos goes beyond the time bar limit
				if(grabbedTickIndex && xPos <= TIMEBAR_LIMIT)
				{
					xPos = oldXPos;
				}
				
				_magnifier.magnify(timeToX(xToTime(xPos)));
				_autoSnap(xPos);
				moveTick = true;
			}
			else if(isNearTick)
			{
				_autoSnap(nearTick);
				isNearTick = false;
				nearTick = 0;
			}
			else
				_autoSnap(xPos);
		}
		
		/**
		 * End of time control interaction
		 */
		private function _endTap(event:MouseEvent):void
		{
			//remove grabbedTick timer if it hasn't complete countdown when user ends touch
			if(grabbedTickTimer.currentCount == 0)
			{
				grabbedTickTimer.removeEventListener(TimerEvent.TIMER, _grabTickOnLongTouch);
				grabbedTickTimer.stop();
			}
			
			//Same, route the interaction to the tick mark control if there is a grabbed tick
			if(!KSketch_CanvasView.isPlayer && _tickmarkControl.grabbedTick)
			{
				_tickmarkControl.end_move_markers();
				_magnifier.showTime(toTimeCode(time), timeToFrame(time),timeToX(time));
				_autoSnap(timeToX(time));
				action = "Move Tick Mark on Time Bar";
			}
			
			resetLongTapTimer();
			resetTapSettings();
			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, _moveTap);
			stage.removeEventListener(MouseEvent.MOUSE_UP, _endTap);
			
			contentGroup.addEventListener(MouseEvent.MOUSE_DOWN, downTap);
			contentGroup.addEventListener(MouseEvent.CLICK, _handleTap, false, 0, true);
			contentGroup.addEventListener(MouseEvent.DOUBLE_CLICK, _handleTap, false, 0, true);
			
			//LOG
			_KSketch.logCounter ++;
			var log:XML = <Action/>;
			var date:Date = new Date();
			log.@category = "Time Bar Control";
			log.@type = action;
			//trace("ACTION " + _KSketch.logCounter + ": " + action);
			KSketch2.log.appendChild(log);
		}
		
		private function _handleTap(eventt:MouseEvent):void {
			if (mouseTimeout != "undefined") {
				_doubleTap(eventt);
				clearTimeout(mouseTimeout);
				mouseTimeout = "undefined";
			} else {
				function _handleSingleTap():void {
					_singleTap(eventt);
					mouseTimeout = "undefined";
				}
				mouseTimeout = setTimeout(_handleSingleTap, DOUBLE_CLICK_SPEED);
			}
		}
		
		private function _singleTap(event:MouseEvent):void 
		{
			action = "Open time bar context magnifier (single tap)";
			
			if(!longTap)
			{
				_magnifier.magnify(timeToX(time));
				_keyMagnifier.open(contentGroup,true);
				_keyMagnifier.x = _magnifier.x;
				_keyMagnifier.y = contentGroup.localToGlobal(new Point()).y + contentGroup.y - 106;
			}
			
			_endTap(event);
		}
		
		private function _doubleTap(event:MouseEvent):void 
		{
			action = "Open time bar context menu (double tap)";
			
			_keyMenu.open(contentGroup,true);
			_keyMenu.x = _magnifier.x;
			_keyMenu.position = position;
			
			if(this.position == BAR_TOP)
				_keyMenu.y = contentGroup.localToGlobal(new Point()).y + contentGroup.y + 3;
			else
				_keyMenu.y = contentGroup.localToGlobal(new Point()).y
		
			_endTap(event);
		}
		
		private function resetLongTapTimer():void
		{
			if(longTapTimer)
			{
				longTapTimer.stop();
				longTapTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, _longTap);
				longTapTimer = null;
			}
		}
		
		private function resetTapSettings():void
		{
			//reset boolean properties
			_magnifier.removeMagnification();
			moveTick = false;
			grabbedTickIndex = null;
			isNearTick = false;
		}
		
		private function _grabTickOnLongTouch(event:TimerEvent):void
		{
			KSketch_CanvasView.tracker.trackPageview( "/timebar/grabTick" );
			
			if(!KSketch_CanvasView.isPlayer && _tickmarkControl.grabbedTick && !KSketch_CanvasView.isWebViewer)
			{	
				
				var toShowTime:Number = xToTime(_tickmarkControl.grabbedTick.x);
				_magnifier.showTime(toTimeCode(toShowTime), timeToFrame(toShowTime),timeToX(toShowTime));
				_magnifier.magnify(_tickmarkControl.grabbedTick.x);
			}
			else
			{
				var xPos:Number = contentGroup.globalToLocal(_touchStage).x;
				var timeX:Number = timeToX(time);
				if(Math.abs(xPos - timeX) >KSketch_TickMark_Control.GRAB_THRESHOLD)
					time = xToTime(xPos);
			}
			
			grabbedTickTimer.removeEventListener(TimerEvent.TIMER, _grabTickOnLongTouch);
			grabbedTickTimer.stop();
		}
		
		public function _autoSnap(xPos:Number):void
		{
			time = xToTime(xPos); //Else just change the time
			
			if(showMagnifier)
				_magnifier.magnify(timeToX(time));
		}
		
		/**
		 * Enters the playing state machien
		 */
		public function play(playFromStart:Boolean):void
		{
			_isPlaying = true;
			_timer.delay = KSketch2.ANIMATION_INTERVAL;
			_timer.addEventListener(TimerEvent.TIMER, playHandler);
			_timer.start();
			
			//comment out for player - play from start #50
			if(playFromStart)
				time = 0;
			else
				time = _KSketch.time;
			
			//comment out for editor - play from start #50
			//time = 0;
			
			_maxPlayTime = _KSketch.maxTime + PLAY_ALLOWANCE;
			
			_rewindToTime = time;
			this.dispatchEvent(new Event(KSketch_TimeControl.PLAY_START));
			
			_KSketch.removeEventListener(KTimeChangedEvent.EVENT_TIME_CHANGED, _transitionHelper.updateWidget);
			_KSketch.addEventListener(KTimeChangedEvent.EVENT_TIME_CHANGED, _transitionHelper.updateMovingWidget);
		}
		
		/**
		 * Updates the play state machine
		 * Different from record handler because it stops on max time
		 */
		private function playHandler(event:TimerEvent):void 
		{
			if(time >= _maxPlayTime)
			{
				time = _rewindToTime;
				stop();
			}
			else
				time = time + KSketch2.ANIMATION_INTERVAL;
		}
		
		/**
		 * Stops playing and remove listener from the timer
		 */
		public function stop():void
		{
			_timer.removeEventListener(TimerEvent.TIMER, playHandler);
			_timer.stop();
			_isPlaying = false;
			this.dispatchEvent(new Event(KSketch_TimeControl.PLAY_STOP));
			_KSketch.removeEventListener(KTimeChangedEvent.EVENT_TIME_CHANGED, _transitionHelper.updateMovingWidget);
			_KSketch.addEventListener(KTimeChangedEvent.EVENT_TIME_CHANGED, _transitionHelper.updateWidget);
		}
				
		/**
		 * Starts the recording state machine
		 * Also sets a timer delay according the the recordingSpeed variable
		 * for this time control
		 */
		public function startRecording():void
		{
			KSketch_CanvasView.tracker.trackPageview( "/timebar/recording" );
			if(recordingSpeed <= 0)
				throw new Error("One does not record in 0 or negative time!");
			
			//The bigger the recording speed, the faster the recording
			_timer.delay = KSketch2.ANIMATION_INTERVAL * recordingSpeed;
			_timer.addEventListener(TimerEvent.TIMER, recordHandler);
			_timer.start();
		}
		
		/**
		 * Advances the time during recording
		 * Extends the time if max is reached
		 */
		private function recordHandler(event:TimerEvent):void 
		{
			if(!_isPlaying)
				time = time + KSketch2.ANIMATION_INTERVAL;
		}
		
		/**
		 * Stops the recording event
		 */
		public function stopRecording():void
		{
			_timer.removeEventListener(TimerEvent.TIMER, recordHandler);
			_timer.stop();
			this.dispatchEvent(new Event(KSketch_TimeControl.PLAY_STOP));
		}
		
		/**
		 * Converts a time value to frame value
		 */
		public function timeToFrame(value:Number):int
		{
			return int(value/KSketch2.ANIMATION_INTERVAL);
		}
		
		/**
		 * Converts a time value to a x position;
		 */
		public function timeToX(value:Number):Number
		{
			var xPos: Number = timeToFrame(value)/(_maxFrame*1.0) * backgroundFill.width;
			xPos = roundToNearestTenth(xPos);
			return xPos;
		}
		
		/**
		 * Converts x to time based on this time control
		 */
		public function xToTime(value:Number):Number
		{
			var currentFrame:int = Math.ceil(value/pixelPerFrame);
			return currentFrame * KSketch2.ANIMATION_INTERVAL;
		}
		
		/**
		 * Num Pixels per frame
		 */
		public function get pixelPerFrame():Number
		{
			return backgroundFill.width/_maxFrame;
		}
		
		/**
		 * Returns the given time (milliseconds) as a SS:MM String
		 */
		public static function toTimeCode(milliseconds:Number):String
		{
			var seconds:int = Math.floor((milliseconds/1000));
			var strSeconds:String = seconds.toString();
			if(seconds < 10)
				strSeconds = "0" + strSeconds;
			
			var remainingMilliseconds:int = (milliseconds%1000)/10;
			var strMilliseconds:String = remainingMilliseconds.toString();
			strMilliseconds = strMilliseconds.charAt(0) + strMilliseconds.charAt(1);
			
			if(remainingMilliseconds < 10)
				strMilliseconds = "0" + strMilliseconds;
			
			var timeCode:String = strSeconds + '.' + strMilliseconds;
			return timeCode;
		}
		
		public static function roundToNearestTenth(value:Number):int
		{
			var newValue:int = Math.floor(value/10) * 10;
			return newValue;
		}
	}
}