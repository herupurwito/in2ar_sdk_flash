package arsupport.demo.away3dlite
{
	import arsupport.away3dlite.ARAway3DLiteContainer;
	import away3dlite.materials.ColorMaterial;
	import away3dlite.primitives.Plane;

	import away3dlite.core.base.Object3D;
	import away3dlite.loaders.Collada;
	import away3dlite.loaders.data.MaterialData;
	import away3dlite.materials.BitmapMaterial;

	import flash.display.Bitmap;

	/**
	 * @author Eugene Zatepyakin
	 */
	public final class In2ArLogo extends ARAway3DLiteContainer
	{
		[Embed(source="../../../../assets/in2ar_logo/logo.png")] private static var Charmap:Class;
		[Embed(source="../../../../assets/in2ar_logo/logo.dae", mimeType="application/octet-stream")] private static var Charmesh:Class;
		
		private var marioMaterial:BitmapMaterial;
		
		private var collada:Collada;
		private var model:Object3D;
		
		public var world3d:Away3DLiteWorld;
		
		public function In2ArLogo(world3d:Away3DLiteWorld)
		{
			super();
			
			this.world3d = world3d;
			
			initObjects();
		}
		
		private function initObjects():void
		{
			collada = new Collada();
			collada.scaling = 13;
			
			collada.parseGeometry(Charmesh) as Object3D;
			model = collada.container;
			
			marioMaterial = new BitmapMaterial(Bitmap(new Charmap()).bitmapData);
        	
			model.y = 120;
			model.z = 70;
			model.rotationY = 45 + 180;
			for each (var _materialData:MaterialData in model.materialLibrary)
            {
				if(_materialData.materialType == MaterialData.TEXTURE_MATERIAL) 
				{
					_materialData.material = marioMaterial;
				}
            } 
			this.addChild(model);
		}
	}
}
