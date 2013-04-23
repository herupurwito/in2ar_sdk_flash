package  
{
    import aerys.minko.render.Viewport;
    import aerys.minko.scene.node.Camera;
    import aerys.minko.scene.node.Group;
    import aerys.minko.scene.node.mesh.geometry.primitive.QuadGeometry;
    import aerys.minko.scene.node.mesh.Mesh;
    import aerys.minko.scene.node.Scene;
    import aerys.minko.type.math.Vector4;
    import arsupport.demo.minko.In2ArLogo;
    import arsupport.minko.MinkoIN2ARController;
    import arsupport.minko.MinkoCameraController;
    import arsupport.minko.MinkoCaptureGeometry;
    import arsupport.minko.MinkoCaptureMesh;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.ByteArray;
    import ru.inspirit.asfeat.ASFEAT;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
    import ru.inspirit.asfeat.IASFEAT;
    
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(width='640', height='480', frameRate='30',backgroundColor='0xFFFFFF')]
    public final class MinkoDemo extends Sprite 
    {
        // tracking data file
		[Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
		public static const DefinitionaData:Class;
        
        //asfeat variables
        public var asfeat:ASFEAT;
		public var asfeatLib:IASFEAT;
        public var intrinsic:IntrinsicParameters;
        public var maxPoints:int = 300; // max points to allow to detect
        public var maxReferences:int = 1; // max objects will be used
        public var maxTrackIterations:int = 3; // track iterations
		
		//engine variables
		private var scene:Scene;
		private var camera:Camera;
		private var view:Viewport;
		
		// different visual objects
        public static var text:TextField;
		
		// 3d stuff
        private var cameraController:MinkoCameraController;
        private var cameraMesh:MinkoCaptureMesh;
        private var model:In2ArLogo;
        private var controller:MinkoIN2ARController;
		
        // Capture stuff
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 30;
        
        public function MinkoDemo() 
        {
            asfeat = new ASFEAT(null);
			asfeat.addEventListener(Event.INIT, init); // wait before this event fired or it wont work
            
            mouseChildren = false;
            mouseEnabled = false;
        }
        
        private function init(e:Event = null):void
		{            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            //stage.quality = StageQuality.LOW;
            
            initNativeCamera();
			initASFEAT();
			initEngine();
			initText();
			initObjects();
			initListeners();
		}
        
        private function initASFEAT():void
		{
            asfeat.removeEventListener(Event.INIT, init);
            asfeatLib = asfeat.lib;
			
			// init our engine
            asfeatLib.init( streamW, streamH, maxPoints, maxReferences, 100, stage );
            
            // indexing reference data will result in huge
            // speed up during matching (see docs for more info)
            // !!! u always need to setup indexing even if u dont plan to use it !!!
            asfeatLib.setupIndexing(12, 10, true);
            
            // but u can switch it off if u want
            asfeatLib.setUseLSHDictionary(true);
            
			asfeatLib.addReferenceObject( ByteArray( new DefinitionaData ) );
			
            // ATTENTION 
			// limit the amount of references to be detected per frame
            // if u have only one reference u can skip this option
			asfeatLib.setMaxReferencesPerFrame(1);
		}
        
        private var stageW:int = 640;
        private var stageH:int = 480;
        private function initEngine():void
		{
			intrinsic = asfeatLib.getIntrinsicParams();
            
            stageW = streamW;// stage.stageWidth;
            stageH = streamH;// stage.stageHeight;
			
            view = new Viewport(2, stageW, stageH);
            scene = new Scene();
            camera = new Camera();
            
            cameraMesh = new MinkoCaptureMesh(view.width, view.height, 
                                                streamW, streamH, 
                                                MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL);
            cameraMesh.setupForBitmapData(buffer);
            
            // calculate cam scale
            var sc:Number = Math.max(stageW / streamW, stageH / streamH);
            cameraController = new MinkoCameraController(intrinsic, sc);
            camera.removeAllControllers();
            camera.addController(cameraController);
            
            scene.addChild(camera);
            scene.addChild(cameraMesh);
			
			addChild(view);
		}
		
		private function initText():void
		{
			// DEBUG TEXT FIELD
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
            text.background = true;
            text.backgroundColor = 0x000000;
            text.textColor = 0xFFFFFF;
			text.width = 300;
			text.height = 18;
			text.selectable = false;
			text.mouseEnabled = false;
            text.y = stage.stageHeight - text.height;
			addChild(text);
		}
		
        private var group:Group;
		private function initObjects():void
		{
            model = new In2ArLogo();
            
            group = new Group(model);
            
            controller = new MinkoIN2ARController(maxReferences);
            controller.addReference(0, group);
            
            scene.addChild(group);
		}
		
		private function initListeners():void
		{
            asfeatLib.addListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeatLib.addListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:Event = null):void
		{
            buffer.draw(video);
            asfeatLib.detect(buffer);
            cameraMesh.invalidate();
            controller.lost();
            scene.render(view);
		}
		
		private function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			
			for(var i:int = 0; i < n; ++i) {
				ref = refList[i];
				state = ref.detectType;
				
				controller.setTransform( ref.id, ref.rotationMatrix, ref.translationVector, ref.poseError, false );
				text.text = state;
                text.appendText( ' @ ' + ref.id );
				
				if(state == '_detect')
					text.appendText( ' :: matched: ' + ref.matchedPointsCount );
			}
		}
        
        private function onDetectionFailed(e:ASFEATDetectionEvent):void 
        {
            text.text = "nothing found";
        }
        
        private var video:Video;
        private var buffer:BitmapData;
        private function initNativeCamera():void
		{
			var camera:flash.media.Camera = flash.media.Camera.getCamera();
			camera.setMode(streamW, streamH, streamFPS, false);
			
			video = new Video(camera.width, camera.height);
			video.attachCamera(camera);
			
			buffer = new BitmapData(streamW, streamH, false, 0x00);
		}
        
    }

}