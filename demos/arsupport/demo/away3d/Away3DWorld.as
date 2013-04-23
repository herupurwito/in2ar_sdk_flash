package arsupport.demo.away3d
{
	import arsupport.away3d.ARAway3DCamera;
	import arsupport.away3d.ARAway3DContainer;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import ru.inspirit.asfeat.calibration.IntrinsicParameters;




	/**
	 * @author Eugene Zatepyakin
	 */
	public final class Away3DWorld extends Sprite
	{
		public var view3d:View3D;
		public var camera3d:ARAway3DCamera;
		public var scene3d:Scene3D;
		
		public var in2ar:In2ArLogo;
		public var obj3d:Vector.<ARAway3DContainer>;
		
		public function Away3DWorld(intrinsic:IntrinsicParameters, viewportW:int = 640, viewportH:int = 480)
		{
			scene3d = new Scene3D();
			camera3d = new ARAway3DCamera( intrinsic, 1.0 );
			view3d = new View3D(
								{x:viewportW * 0.5, y:viewportH * 0.5, scene:scene3d, camera:camera3d}
								);
            
            this.addChild(view3d);
			
			obj3d = new Vector.<ARAway3DContainer>();
		}
		
		public function updateAROptions(viewportToSourceWidthRatio:Number = 1.0):void
        {
            camera3d.updateProjectionMatrix(viewportToSourceWidthRatio);
        }
		
		public function initIn2ArLogo():void
		{
			in2ar = new In2ArLogo(this);
            scene3d.addChild(in2ar);
			obj3d.push(in2ar);
		}
		
		public function initPlane(w:int, h:int):void
		{
			var plane:IdentPlane = new IdentPlane(this, w, h);
            scene3d.addChild(plane);
			obj3d.push(plane);
		}
		
		public function render(e:Event = null):void
		{			
			view3d.render();
		}
	}
}
