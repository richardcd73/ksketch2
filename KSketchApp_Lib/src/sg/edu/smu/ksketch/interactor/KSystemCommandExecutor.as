/**------------------------------------------------
 * Copyright 2012 Singapore Management University
 * All Rights Reserved
 *
 *-------------------------------------------------*/

package sg.edu.smu.ksketch.interactor
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.geom.Point;
	
	import sg.edu.smu.ksketch.components.KCanvas;
	import sg.edu.smu.ksketch.io.KFileLoader;
	import sg.edu.smu.ksketch.io.KFileParser;
	import sg.edu.smu.ksketch.logger.KLogger;
	import sg.edu.smu.ksketch.model.IKeyFrame;
	import sg.edu.smu.ksketch.model.KImage;
	import sg.edu.smu.ksketch.model.KObject;
	import sg.edu.smu.ksketch.model.geom.K2DVector;
	import sg.edu.smu.ksketch.model.geom.K3DVector;
	import sg.edu.smu.ksketch.model.geom.KPathPoint;
	import sg.edu.smu.ksketch.operation.IModelOperation;
	import sg.edu.smu.ksketch.operation.KModelFacade;
	import sg.edu.smu.ksketch.operation.implementations.KAddOperation;
	import sg.edu.smu.ksketch.operation.implementations.KInteractionOperation;
	import sg.edu.smu.ksketch.utilities.IIterator;
	import sg.edu.smu.ksketch.utilities.KAppState;
	import sg.edu.smu.ksketch.utilities.KModelObjectList;
	
	public class KSystemCommandExecutor extends KLoggerCommandExecutor
	{
		private static const _SYSTEM_COMMAND_PREFIX:String = "sys";

		public function KSystemCommandExecutor(appState:KAppState, canvas:KCanvas, facade:KModelFacade)
		{
			super(appState, canvas, facade);
		}
		
		public static function isSystemCommand(command:String):Boolean
		{
			return command.indexOf(_SYSTEM_COMMAND_PREFIX) == 0;
		}
		
		public static function isOperationCommand(command:String):Boolean
		{
			return isSystemCommand(command) && !isPlayerCommand(command) && 
				command != KLogger.SYSTEM_NEW && command != KLogger.SYSTEM_SAVE && 
				command != KLogger.SYSTEM_COPY && command != KLogger.SYSTEM_CLEARCLIPBOARD;
		}
		
		public static function isPlayerCommand(command:String):Boolean
		{
			return command == KLogger.SYSTEM_PLAY || command == KLogger.SYSTEM_PAUSE || 
				command == KLogger.SYSTEM_REWIND || command == KLogger.SYSTEM_PREVFRAME || 
				command == KLogger.SYSTEM_NEXTFRAME || command == KLogger.SYSTEM_SLIDERDRAG || 
				command == KLogger.SYSTEM_GUTTERTAP;
		}
		
		public static function isLoadCommand(command:String):Boolean
		{
			return command.indexOf(KLogger.SYSTEM_LOAD) == 0;
		}
		
		public override function initCommand(commandNode:XML):void
		{
			var command:String = commandNode.name();
			switch (command)
			{
				case KLogger.SYSTEM_UNDO:
					undoSystemCommand();
					break;
				case KLogger.SYSTEM_REDO:
					redoSystemCommand();
					break;
				case KLogger.SYSTEM_IMAGE:
					_image(commandNode);
					break;
				case KLogger.SYSTEM_STROKE:
					_stroke(commandNode);
					break;
				case KLogger.SYSTEM_ERASE:
					_erase(commandNode);
					break;
				case KLogger.SYSTEM_COPY:
					_copy(commandNode);
					break;
				case KLogger.SYSTEM_CUT:
					_cut(commandNode);
					break;
				case KLogger.SYSTEM_PASTE:
					_paste(commandNode);
					break;
				case KLogger.SYSTEM_CLEARCLIPBOARD:
					_clearClipBoard(commandNode);
					break;
				case KLogger.SYSTEM_TOGGLEVISIBILITY:
					_toggleVisibility(commandNode);
					break;
				case KLogger.SYSTEM_GROUP:
					_group(commandNode);
					break;
				case KLogger.SYSTEM_UNGROUP:
					_ungroup(commandNode);
					break;
				case KLogger.SYSTEM_REGROUP:
					_regroup(commandNode);
					break;
				case KLogger.SYSTEM_TRANSLATE:
					_translate(commandNode);
					break;
				case KLogger.SYSTEM_ROTATE:
					_rotate(commandNode);
					break;
				case KLogger.SYSTEM_SCALE:
					_scale(commandNode);
					break;
				case KLogger.SYSTEM_SETOBJECTNAME:
					_setObjectName(commandNode);
					break;
				case KLogger.SYSTEM_RETIMEKEYS:
					_retimeKeys(commandNode);
					break;
			//	default:
			//		super.initCommand(command,commandNode);
			}
		}
		
		public function undoAllCommand():void
		{
			while (_appState.undoEnabled)
				_appState.undo();
		}
		
		public function undoSystemCommand():void
		{
			_appState.undo();
		}
		
		public function redoSystemCommand():void
		{
			_appState.redo();
		}
		
		public function redoPlayerCommand(commandNode:XML):void
		{
			_appState.time = _getNumber(commandNode,KLogger.TIME_FROM);
			var command:String = commandNode.name();
			if (command == KLogger.SYSTEM_PLAY)
				_appState.startPlaying();
			else if (command == KLogger.SYSTEM_PAUSE)
				_appState.pause();
			else if (command == KLogger.SYSTEM_REWIND)
				_first();
			else if (command == KLogger.SYSTEM_PREVFRAME)
				_previous()
			else if (command == KLogger.SYSTEM_NEXTFRAME)
				_next();
			else if (command == KLogger.SYSTEM_SLIDERDRAG)
				_appState.time = _getNumber(commandNode,KLogger.TIME_TO);
			else if (command == KLogger.SYSTEM_GUTTERTAP)
				_appState.time = _getNumber(commandNode,KLogger.TIME_TO);
		}
		
		public function undoPlayerCommand(commandNode:XML):void
		{
			var command:String = commandNode.name();
			if (command == KLogger.SYSTEM_PLAY)
				_appState.pause();
			else if (command == KLogger.SYSTEM_PAUSE)
				_appState.startPlaying();
			else if (command == KLogger.SYSTEM_REWIND)
				_appState.time = _getNumber(commandNode,KLogger.TIME_FROM);
			else if (command == KLogger.SYSTEM_PREVFRAME)
				_next()
			else if (command == KLogger.SYSTEM_NEXTFRAME)
				_previous();
			else if (command == KLogger.SYSTEM_SLIDERDRAG)
				_appState.time = _getNumber(commandNode,KLogger.TIME_FROM);
			else if (command == KLogger.SYSTEM_GUTTERTAP)
				_appState.time = _getNumber(commandNode,KLogger.TIME_FROM);
		}
		
		public function load(commandNode:XML):void
		{
			var filename:String = commandNode.attribute(KLogger.FILE_NAME);
			var location:String = commandNode.attribute(KLogger.FILE_LOCATION);
			var file:File = KFileParser.resolvePath(filename,
				location ? location : KLogger.FILE_DESKTOP_DIR);
			if (file.exists)
			{
				var xml:XML = new KFileLoader().loadKMVFromFile(file);
				_canvas.loadFile(xml);
				KLogger.setLogFile(new XML(xml.child(KLogger.COMMANDS)));
			}
		}

		private function _image(commandNode:XML):void
		{
			var x:Number = _getNumber(commandNode,KLogger.IMAGE_X);
			var y:Number = _getNumber(commandNode,KLogger.IMAGE_Y);
			var data:String = commandNode.attribute(KLogger.IMAGE_DATA);
			_appState.time = _getNumber(commandNode,KLogger.TIME);			
			var op:IModelOperation = _facade.addKImage(null,_appState.time,x,y)
			_appState.addOperation(op);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, 
				function (event:Event):void
				{
					var image:KImage = ((op as KAddOperation).object as KImage); 
					image.imageData = event.target.content.bitmapData;
				});
			loader.loadBytes(KFileParser.stringToByteArray(data));
		}	
		
		private function _stroke(commandNode:XML):void
		{
			var color:uint = uint(commandNode.attribute(KLogger.STROKE_COLOR));
			var thickness:Number = _getNumber(commandNode,KLogger.STROKE_THICKNESS);
			var points:Vector.<Point> = _getPoints(commandNode,KLogger.STROKE_POINTS);
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_facade.beginKStrokePoint(color,thickness,_appState.time);
			for (var i:int; i < points.length; i++)
				_facade.addKStrokePoint(points[i].x,points[i].y);
			var op:IModelOperation = _facade.endKStrokePoint();
			_appState.addOperation(new KInteractionOperation(
				_appState,_appState.time,_appState.time,null,null,op));
		}	
		
		private function _erase(commandNode:XML):void
		{
			var obj:KObject = _getObjects(commandNode).getObjectAt(0);
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.erase(obj,_appState.time));
		}	
		
		private function _copy(commandNode:XML):void
		{
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_facade.copy(_getObjects(commandNode),_appState.time);
		}	
		
		private function _cut(commandNode:XML):void
		{
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.cut(_getObjects(commandNode),_appState.time));
		}	
		
		private function _paste(commandNode:XML):void
		{
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.paste(
				_getBoolean(commandNode,KLogger.PASTEINCLUDEMOTION),
				_getNumber(commandNode,KLogger.TIME)));
		}	
		
		private function _clearClipBoard(commandNode:XML):void
		{
			_facade.clearClipBoard();
		}	
		
		private function _toggleVisibility(commandNode:XML):void
		{
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.toggleVisibility(
				_getObjects(commandNode),_appState.time));
		}	
		
		private function _group(commandNode:XML):void
		{
			var objs:KModelObjectList = _getObjects(commandNode);
			var mode:String = _getGroupingMode(commandNode);
			var type:int = _getTransitionType(commandNode);
			var real:Boolean = _getBoolean(commandNode,KLogger.GROUPING_ISREALTIMETRANSLATION);
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.group(objs,mode,type,_appState.time,real));
		}	
		
		private function _ungroup(commandNode:XML):void
		{
			var objs:KModelObjectList = _getObjects(commandNode);
			var mode:String = _getGroupingMode(commandNode);
			var type:int = _getTransitionType(commandNode);
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.ungroup(objs,mode,_appState.time));			
		}	
		
		private function _regroup(commandNode:XML):void
		{
			var objs:KModelObjectList = _getObjects(commandNode);
			var mode:String = _getGroupingMode(commandNode);
			var type:int = _getTransitionType(commandNode);
			var real:Boolean = _getBoolean(commandNode,KLogger.GROUPING_ISREALTIMETRANSLATION);
			_appState.time = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.regroup(objs,mode,type,_appState.time,real));		
		}	
		
		private function _translate(commandNode:XML):void
		{
			var obj:KObject = _getObjects(commandNode).getObjectAt(0);
			var type:int = _getTransitionType(commandNode);
			var startTime:Number = _getStartTime(commandNode);
			var endTime:Number = _getEndTime(commandNode);
			var oldSel:KSelection = _appState.selection;
			_appState.selection = new KSelection(_getObjects(commandNode),endTime);
			_beginTranslation(obj,startTime,type);
			_addToTranslation(obj,_get3DPoints(commandNode,KLogger.TRANSITION_PATH));
			var op:IModelOperation = _endTranslation(obj, endTime);
			_appState.addOperation(new KInteractionOperation(_appState,
				startTime,endTime,oldSel,_appState.selection,op));
		}	
		
		private function _rotate(commandNode:XML):void
		{
			var obj:KObject = _getObjects(commandNode).getObjectAt(0);
			var type:int = _getTransitionType(commandNode);
			var startTime:Number = _getStartTime(commandNode);
			var endTime:Number = _getEndTime(commandNode);
			var centerX:Number = _getNumber(commandNode,KLogger.TRANSITION_CENTER_X);
			var centerY:Number = _getNumber(commandNode,KLogger.TRANSITION_CENTER_Y);
			var oldSel:KSelection = _appState.selection;
			_appState.selection = new KSelection(_getObjects(commandNode),endTime);
			_beginRotation(obj,new Point(centerX,centerY),startTime,type);
			_addToRotation(obj,_get2DPoints(commandNode,KLogger.TRANSITION_PATH),
				_getPathPoints(commandNode,KLogger.MOTION_PATH));
			var op:IModelOperation = _endRotation(obj, endTime);
			_appState.addOperation(new KInteractionOperation(_appState,
				startTime,endTime,oldSel,_appState.selection,op));
		}	
		
		private function _scale(commandNode:XML):void
		{
			var obj:KObject = _getObjects(commandNode).getObjectAt(0);
			var type:int = _getTransitionType(commandNode);
			var startTime:Number = _getStartTime(commandNode);
			var endTime:Number = _getEndTime(commandNode);
			var centerX:Number = _getNumber(commandNode,KLogger.TRANSITION_CENTER_X);
			var centerY:Number = _getNumber(commandNode,KLogger.TRANSITION_CENTER_Y);
			var oldSel:KSelection = _appState.selection;
			_appState.selection = new KSelection(_getObjects(commandNode),endTime);
			_beginScale(obj,new Point(centerX,centerY),startTime,type);
			_addToScale(obj,_get2DPoints(commandNode,KLogger.TRANSITION_PATH),
				_getPathPoints(commandNode,KLogger.MOTION_PATH));
			var op:IModelOperation = _endScale(obj, endTime);
			_appState.addOperation(new KInteractionOperation(_appState,
				startTime,endTime,oldSel,_appState.selection,op));
		}	
		
		private function _setObjectName(commandNode:XML):void
		{
			var id:int = _getInt(commandNode,KLogger.OBJECTS);
			var name:String = commandNode.attribute(KLogger.NAME);
			_facade.setObjectName(_facade.getObjectByID(id),name);
		}
		
		private function _retimeKeys(commandNode:XML):void
		{
			var keys:Vector.<IKeyFrame> = _getKeys(commandNode);
			var retimeTos:Vector.<Number> = _getNumbers(commandNode,KLogger.KEYFRAME_RETIMETOS);
			var appTime:Number = _getNumber(commandNode,KLogger.TIME);
			_appState.addOperation(_facade.retimeKeys(keys,retimeTos,appTime));
		}
		
		private function _beginTranslation(object:KObject, time:Number, type:int):void
		{
			_facade.beginTranslation(object,_appState.time = time,type);
		}
		
		private function _addToTranslation(object:KObject,k3DPts:Vector.<K3DVector>):void
		{
			for (var i:int=0; i < k3DPts.length; i++)
				_facade.addToTranslation(object,k3DPts[i].x,
					k3DPts[i].y,_appState.time = k3DPts[i].z);
		}
		
		private function _endTranslation(object:KObject, time:Number):IModelOperation
		{
			return _facade.endTranslation(object, _appState.time = time);			
		}
		
		private function _beginRotation(object:KObject, center:Point, time:Number, type:int):void
		{
			_facade.beginRotation(object, center, _appState.time = time, type);
		}
		
		private function _addToRotation(object:KObject,k2DPts:Vector.<K2DVector>,
										pathPts:Vector.<KPathPoint>):void
		{
			for (var i:int=0; i < k2DPts.length; i++)
				_facade.addToRotation(object,k2DPts[i].x,pathPts[i],_appState.time=k2DPts[i].y);
		}
		
		private function _endRotation(object:KObject, time:Number):IModelOperation
		{
			return _facade.endRotation(object, _appState.time = time);			
		}
		
		private function _beginScale(object:KObject, center:Point, time:Number, type:int):void
		{
			_facade.beginScale(object, center, _appState.time = time, type);
		}
		
		private function _addToScale(object:KObject,k2DPts:Vector.<K2DVector>,
									 pathPts:Vector.<KPathPoint>):void
		{
			for (var i:int=0; i < k2DPts.length; i++)
				_facade.addToScale(object,k2DPts[i].x,pathPts[i],_appState.time=k2DPts[i].y);
		}
		
		private function _endScale(object:KObject, time:Number):IModelOperation
		{
			return _facade.endScale(object, _appState.time = time);			
		}
		
		private function _getGroupingMode(commandNode:XML):String
		{
			return commandNode.attribute(KLogger.GROUPING_MODE);
		}
		
		private function _getTransitionType(commandNode:XML):int
		{
			return _getInt(commandNode,KLogger.TRANSITION_TYPE);
		}
		
		private function _getStartTime(commandNode:XML):Number
		{
			return _getNumber(commandNode,KLogger.TRANSITION_START_TIME);
		}
		
		private function _getEndTime(commandNode:XML):Number
		{
			return _getNumber(commandNode,KLogger.TRANSITION_END_TIME);
		}		
		
		private function _getKeys(commandNode:XML):Vector.<IKeyFrame>
		{
			var objectIDs:Vector.<int> = _getInts(commandNode,KLogger.OBJECTS);
			var keyTypes:Vector.<int> = _getInts(commandNode,KLogger.KEYFRAME_TYPES);
			var keyTimes:Vector.<Number> = _getNumbers(commandNode,KLogger.KEYFRAME_TIMES);
			var keys:Vector.<IKeyFrame> = new Vector.<IKeyFrame>();
			var key:IKeyFrame;
			for (var i:int=0; i < objectIDs.length; i++)
			{
				key = _facade.getObjectByID(objectIDs[i]).getKeyframe(keyTypes[i],keyTimes[i]);
				if (key != null)
					keys.push(key);
			}
			return keys;
		}
		
		private function _getObjects(commandNode:XML):KModelObjectList
		{
			var list:KModelObjectList = new KModelObjectList();
			var ints:Vector.<int> = _getInts(commandNode,KLogger.OBJECTS);
			for (var i:int = 0; i < ints.length; i++)
				list.add(_facade.getObjectByID(ints[i]));
			return list;
		}
		
		private function _getPoints(commandNode:XML,attribute:String):Vector.<Point>
		{
			return KFileParser.stringToPoints(commandNode.attribute(attribute));
		}
		
		private function _getPathPoints(commandNode:XML,attribute:String):Vector.<KPathPoint>
		{
			return KFileParser.stringToPathPoints(commandNode.attribute(attribute));
		}
		
		private function _get2DPoints(commandNode:XML,attribute:String):Vector.<K2DVector>
		{
			return KFileParser.stringToK2DVectors(commandNode.attribute(attribute));
		}
		
		private function _get3DPoints(commandNode:XML,attribute:String):Vector.<K3DVector>
		{
			return KFileParser.stringToK3DVectors(commandNode.attribute(attribute));
		}
		
		private function _getNumbers(commandNode:XML,attribute:String):Vector.<Number>
		{
			return KFileParser.stringToNumbers(commandNode.attribute(attribute));
		}
		
		private function _getNumber(commandNode:XML,attribute:String):Number
		{
			return Number(commandNode.attribute(attribute));
		}
		
		private function _getInts(commandNode:XML,attribute:String):Vector.<int>
		{
			return KFileParser.stringToInts(commandNode.attribute(attribute));
		}
		
		private function _getInt(commandNode:XML,attribute:String):Number
		{
			return int(commandNode.attribute(attribute));
		}
		
		private function _getBoolean(commandNode:XML,attribute:String):Boolean
		{
			return Boolean(commandNode.attribute(attribute));
		}
		
	}
}