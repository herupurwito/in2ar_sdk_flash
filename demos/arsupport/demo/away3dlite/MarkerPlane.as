package arsupport.demo.away3dlite 
{
	import arsupport.away3dlite.ARAway3DLiteContainer;
	import away3dlite.materials.BitmapMaterial;
	import away3dlite.primitives.Plane;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Eugene Zatepyakin
	 */
	public final class MarkerPlane extends ARAway3DLiteContainer 
	{
		[Embed(source = '../../../../assets/def_marker_500.jpg')] protected static const marker_ass:Class;
		[Embed(source = '../../../../pbj/relight.pbj', mimeType = 'application/octet-stream')] protected static const shad_ass:Class;
		
		public var world3d:Away3DLiteWorld;
		public var img:BitmapData = Bitmap(new marker_ass).bitmapData;
		public var mat:BitmapMaterial;
		
		protected var _light_shader:Shader;
		
		public function MarkerPlane(world3d:Away3DLiteWorld, w:int = 550, h:int = 440) 
		{
			super();
			
			this.world3d = world3d;
			
			buildModel(w, h);
		}
		public function initShader():void
		{
			_light_shader = new Shader(new shad_ass() as ByteArray);
			_light_shader.data.src.width = img.width;
			_light_shader.data.src.height = img.height;
			_light_shader.data.src.input = img;
			_light_shader.data.irradiance.value = [ 1.0, 1.0, 1.0, 1.0 ];
			_light_shader.data.bias.value = [ 0., 0., 0., 0. ];
		}
		public function updateLight(r:Number, g:Number, b:Number):void
		{
			_light_shader.data.irradiance.value = [ r, g, b, 1.0 ];
			var job:ShaderJob = new ShaderJob(_light_shader, mat.bitmapData, img.width, img.height);
			job.start();
		}
		private function buildModel(w:int = 550, h:int = 440):void
		{
			mat = new BitmapMaterial(img.clone());
			mat.smooth = true;
			var plane:Plane = new Plane(mat, w, h);
			plane.rotationX = -90;
			plane.rotationZ = 180;
			
			this.addChild( plane );
		}
		
	}

}