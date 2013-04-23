package arsupport.demo.away3d
{
	import arsupport.away3d.ARAway3DContainer;

	import away3d.containers.ObjectContainer3D;
	import away3d.core.utils.Cast;
	import away3d.loaders.Collada;
	import away3d.loaders.data.MaterialData;
	import away3d.materials.BitmapMaterial;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class In2ArLogo extends ARAway3DContainer
	{
		[Embed(source="../../../../assets/in2ar_logo/logo.png")] private static var Charmap:Class;
		[Embed(source="../../../../assets/in2ar_logo/logo.dae", mimeType="application/octet-stream")] private static var Charmesh:Class;
		
		private var collada:Collada;
		private var model:ObjectContainer3D;
		
		public var world3d:Away3DWorld;
		
		public function In2ArLogo(world3d:Away3DWorld)
		{
			super();
			
			this.world3d = world3d;
			
			initObjects();
		}
		
		private function initObjects():void
		{
			collada = new Collada();
			collada.scaling = 15;
			
			model = collada.parseGeometry(Charmesh) as ObjectContainer3D;
			model.mouseEnabled = false;
			
			var mat:BitmapMaterial = new BitmapMaterial(Cast.bitmap(Charmap));
        	
			model.y = -120;
			model.z = 70;
			model.rotationY = 45 + 180;
			for each (var _materialData:MaterialData in model.materialLibrary)
            {
				if(_materialData.materialType == MaterialData.TEXTURE_MATERIAL) 
				{
					_materialData.material = mat;
				}
            } 
			
			this.addChild(model);
		}
	}
}
