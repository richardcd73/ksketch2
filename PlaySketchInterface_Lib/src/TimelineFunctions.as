/**------------------------------------------------
*Copyright 2010-2012 Singapore Management University
*Developed under a grant from the Singapore-MIT GAMBIT Game Lab
 
*-------------------------------------------------*/
import flash.events.Event;
import flash.events.MouseEvent;

import mx.binding.utils.BindingUtils;
import mx.controls.Text;
import mx.controls.VRule;

import sg.edu.smu.ksketch.event.KCommandEvent;
import sg.edu.smu.ksketch.event.KModelEvent;
import sg.edu.smu.ksketch.event.KTimeChangedEvent;
import sg.edu.smu.ksketch.interactor.KSelection;
import sg.edu.smu.ksketch.logger.KLogger;
import sg.edu.smu.ksketch.operation.KKeyTimeOperator;
import sg.edu.smu.ksketch.operation.KTransformMgr;
import sg.edu.smu.ksketch.utilities.KAppState;
import sg.edu.smu.playsketch.components.timebar.Marker;
import sg.edu.smu.playsketch.components.timebar.TimeWidget;

import spark.components.HSlider;
import spark.events.TrackBaseEvent;

private var _timeList:Vector.<int>;
private var _timeMarkers:Vector.<VRule>;		
private var _isKSKTimeThumbDragging:Boolean = false;
private var _startKSKTimeValue:Number = -1;
private var _keyFrameInfo:Vector.<Object>;

private function initTimebar():void
{
	_timeList = new Vector.<int>();
	
	BindingUtils.bindSetter(_bindKeyIndexSliderMaxTime,appState, "maxTime");
	BindingUtils.bindSetter(_bindKeyIndexSliderTime,appState, "time");
	BindingUtils.bindSetter(_bindKeyIndexSliderEnabled,appState, "isUserTest");
	slider_key_index.dataTipFormatFunction = showSliderTip;
	slider_key_index.addEventListener(Event.CHANGE,_handleTimeSlider);
	slider_key_index.addEventListener(TrackBaseEvent.THUMB_PRESS,timeSlider_thumbPressHandler);
	slider_key_index.addEventListener(TrackBaseEvent.THUMB_RELEASE,timeSlider_thumbReleaseHandler);
	slider_key_index.addEventListener(MouseEvent.MOUSE_DOWN,slider_time_mouseDownHandler);
	
	_commandExecutor.addEventListener(KLogger.BTN_TOGGLE_TIMEBAR_EXPAND,
		function (e:KCommandEvent):void
		{
			_toogle_TimebarExpand();
		});

}

public function play():void
{
	if(!appState.isAnimating)
		appState.startPlaying();
	else
		appState.pause();
}

private function _bindKeyIndexSliderMaxTime(value:Number):void
{
	slider_key_index.maximum = KAppState.indexOf(value);
}

private function _bindKeyIndexSliderTime(value:Number):void
{
//	trace(appState.time);
	slider_key_index.value = KAppState.indexOf(value);
}

private function _bindKeyIndexSliderEnabled(value:Boolean):void
{
	slider_key_index.enabled = !value;
}

/**
 * Return the slider tip derived from KAppState kskTime.
 */		
public function showSliderTip(value:Number):Object
{
	return "Frame: " + value + "@" + (KAppState.kskTime(value) / 1000) + "s";
}	

/**
 * Set the KAppState time to value
 */		
public function _handleTimeSlider(event:Event):void
{
	if(!_isKSKTimeThumbDragging)
		KLogger.log(KLogger.CHANGE_TIME, KLogger.CHANGE_TIME_TO, slider_key_index.value);
	
	appState.time = KAppState.kskTime(slider_key_index.value);
	//	if(_playButton != null && _appState.time == _appState.maxTime)
	//		_playButton.label = "Play";
}

public function slider_time_mouseDownHandler(event:MouseEvent):void
{
	if(_isKSKTimeThumbDragging)
		return;
	if(_timeList.length > 0 && event.target is HSlider)
	{
		var clickTime:Number = (event.localX / 564) * appState.maxTime; //slider_key_index.width
		var timeTo:int = appState.time;
		
		if(clickTime < appState.time)
			timeTo = _searchTime(_timeList, appState.time, true);
		else if(clickTime > appState.time)
			timeTo = _searchTime(_timeList, appState.time, false);
		appState.time = timeTo;
	}
}

private function _searchTime(timeList:Vector.<int>, time:Number, searchFront:Boolean):int
{
	var result:int;
	for(var i:int=0; i<timeList.length && time>timeList[i]; i++)
		continue;
	if(i == timeList.length)
		result = timeList[timeList.length-1];
	else if(i == timeList.length-1)
		result = searchFront&&timeList.length>1 ? 
			timeList[timeList.length-2] : timeList[timeList.length-1];
	else if (i == 0)
		result = time==timeList[0]&&!searchFront&&timeList.length>1 ? timeList[1] : timeList[0];
	else
		result = searchFront ? timeList[i-1] : (time==timeList[i]?timeList[i+1]:timeList[i]);
	return result; 
}

public function timeSlider_thumbPressHandler(event:TrackBaseEvent):void
{
	if(event.target is HSlider)
	{
		if (appState.selection != null)
			appState.interactingSelection = new KSelection(appState.selection.objects, appState.time);
		_isKSKTimeThumbDragging = true;
		_startKSKTimeValue = (event.target as HSlider).value;
	}	
}

public function timeSlider_thumbReleaseHandler(event:TrackBaseEvent):void
{
	if(!(event.target is HSlider))
		return;
	var keyIndexSlider:HSlider = event.target as HSlider;
	if(keyIndexSlider.value != _startKSKTimeValue)
		KLogger.log(KLogger.CHANGE_TIME, KLogger.CHANGE_TIME_TO, appState.time);
	_isKSKTimeThumbDragging = false;
	_startKSKTimeValue = -1;
	if(appState.isAnimating)
	{
		var newValue:Number = keyIndexSlider.value;
		appState.timerReset(KAppState.kskTime(newValue));
	}
}

private function updateTimeWidgets(event:Event):void
{
	var clusterList:Vector.<Object> = _facade.getMarkerInfo();
	
	var newMarker:Marker;
	var newLinkedMarker:Marker;
	var overviewMarkers:Vector.<Marker> = new Vector.<Marker>();
	var translateMarkers:Vector.<Marker> = new Vector.<Marker>();
	var rotateMarkers:Vector.<Marker> = new Vector.<Marker>();
	var scaleMarkers:Vector.<Marker> = new Vector.<Marker>();
	
	var clusterTime:Number;
	var translateCluster:Vector.<Object>;
	var rotateCluster:Vector.<Object>;
	var scaleCluster:Vector.<Object>;
	
	for each (var cluster:Object in clusterList)
	{
		clusterTime = cluster.time;
		newMarker = _generateMarker(cluster.keyList, TimeWidget.OVERVIEW, clusterTime, cluster.selected);
		
		translateCluster = new Vector.<Object>();
		rotateCluster = new Vector.<Object>();
		scaleCluster = new Vector.<Object>();
		
		for each(var keyInfo:Object in newMarker.keyList)
		{
			if(!keyInfo.selected)
				continue;
			
			switch(keyInfo.type)
			{
				case KKeyTimeOperator.TRANSLATE_KEY:
					translateCluster.push(keyInfo);
					break;
				case KKeyTimeOperator.ROTATE_KEY:
					rotateCluster.push(keyInfo);
					break;
				case KKeyTimeOperator.SCALE_KEY:
					scaleCluster.push(keyInfo);
					break;
				default:
			}
		}
		
		if(translateCluster.length != 0)
		{
			newLinkedMarker = _generateMarker(translateCluster, TimeWidget.TRANSLATE, clusterTime, cluster.selected);
			newLinkedMarker.linkedMarkers.push(newMarker);
			newMarker.linkedMarkers.push(newLinkedMarker);
			translateMarkers.push(newLinkedMarker);
		}
		
		if(rotateCluster.length != 0)
		{
			newLinkedMarker = _generateMarker(rotateCluster, TimeWidget.ROTATE, clusterTime, cluster.selected);
			newLinkedMarker.linkedMarkers.push(newMarker);
			newMarker.linkedMarkers.push(newLinkedMarker);
			rotateMarkers.push(newLinkedMarker);
		}
		
		if(scaleCluster.length != 0)
		{
			newLinkedMarker = _generateMarker(translateCluster, TimeWidget.SCALE, clusterTime, cluster.selected);
			newLinkedMarker.linkedMarkers.push(newMarker);
			newMarker.linkedMarkers.push(newLinkedMarker);
			scaleMarkers.push(newLinkedMarker);
		}
		
		overviewMarkers.push(newMarker);
	}
	
	TimeWidget.widget_max_time = 0;
	
	timeWidget.updateTimeWidget(overviewMarkers);
	
	if(_timeBar_toogled)
	{
		expandedWidget1.updateTimeWidget(translateMarkers);
		expandedWidget2.updateTimeWidget(rotateMarkers);
		expandedWidget3.updateTimeWidget(scaleMarkers);
	}
	rescaleTimeWidgets();
	labelSlider();
}

private function _generateMarker(keyInfoList:Vector.<Object>, type:int, time:Number, selected:Boolean):Marker
{
	var newMarker:Marker = new Marker();
	newMarker.init();
	newMarker.keyList = keyInfoList;
	newMarker.type = type;
	newMarker.time = time;
	newMarker.selected = selected;
	
	for(var i:int = 0; i<keyInfoList.length; i++)
	{
		if(keyInfoList[i].hasTransform)
		{
			newMarker.hasTransform = true;
			break;
		}
	}
	
	return newMarker;
}

private function rescaleTimeWidgets():void
{
	timeWidget.rescaleTimeWidget();
	if(_timeBar_toogled)
	{
		expandedWidget1.rescaleTimeWidget();
		expandedWidget2.rescaleTimeWidget();
		expandedWidget3.rescaleTimeWidget();
	}
	labelSlider();
}

private function _toogle_TimebarExpand():void
{	
	if(_timeBar_toogled)
	{
		timeBar.height = 50;
		expandedWidget1.visible = false;
		expandedWidget2.visible = false;
		expandedWidget3.visible = false;
		_timeBar_toogled = false;
	}
	else
	{
		timeBar.height = 113;
		expandedWidget1.visible = true;
		expandedWidget2.visible = true;
		expandedWidget3.visible = true;
		_timeBar_toogled = true;
	}
	
	updateTimeWidgets(null);
}

public function updateSliderIndicator():void
{
	sliderIndicator.graphics.clear();
	sliderIndicator.graphics.lineStyle(1, 0xFF0000);
	sliderIndicator.graphics.moveTo(_thumbOffset, 20);
	sliderIndicator.graphics.lineTo(_thumbOffset, timeWidgetGroups.height);
	sliderIndicator.depth = 10;
}

public function sliderUpdated():void
{
	sliderIndicator.x = slider_key_index.thumb.x+_thumbOffset;
}

public function labelSlider():void
{
	sliderLabels.removeAllElements();
	
	var fullSecond:Boolean = true;
	var position:Number;
	var modulus:int;
	
	sliderLabels.graphics.clear();
	sliderLabels.graphics.lineStyle(1,0x000000);
	
	var pixelPerInterval:Number = (slider_key_index.width-slider_key_index.thumb.width)/slider_key_index.maximum;
	var stepSize:int = 2;
	var fullSectionSteps:int = 1000/KAppState.ANIMATION_INTERVAL;
	var maxKeys:Number = slider_key_index.maximum;
	
	if(160 < maxKeys)
	{
		stepSize = maxKeys/80;
		fullSectionSteps = stepSize * fullSectionSteps;
	}
	
	for(var i:int = 0; i <= slider_key_index.maximum; i+=stepSize)
	{
		position = i*pixelPerInterval;
		modulus = i%fullSectionSteps;
		sliderLabels.graphics.moveTo(position, sliderLabels.height);
		
		switch(modulus)
		{
			case 0:
				sliderLabels.graphics.lineTo(position, sliderLabels.height*0.2);
				if(i < slider_key_index.maximum)
				{
					var text:Text = new Text();
					text.mouseEnabled = false;
					text.selectable = false;
					text.scaleX = 0.75;
					text.scaleY = 0.75;
					text.text = (i*KAppState.ANIMATION_INTERVAL/1000).toString();
					text.x = position;
					
					if(text.x < slider_key_index.width*0.95)
						sliderLabels.addElement(text);
				}
				break;

			case fullSectionSteps/2:
				sliderLabels.graphics.lineTo(position, sliderLabels.height*0.5);
				break;
			
			default:
				//sliderLabels.graphics.lineTo(position, sliderLabels.height*0.8);
		}
	}
}