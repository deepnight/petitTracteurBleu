package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];

	var type : World.Enum_Item;

	public function new(t:World.Enum_Item, x,y) {
		type = t;
		super(x, y);
		xr = rnd(0.1, 0.9);
		yr = rnd(0.1, 0.9);
		ALL.push(this);

		var tileInf = game.world.getEnumTileInfosFromValue(type);
		var atlas = Assets.ledTilesets.get( tileInf.tileset.identifier );
		var t = atlas.sub( tileInf.x, tileInf.y, tileInf.w, tileInf.h );
		t.setCenterRatio(0.5,1);
		var bmp = new h2d.Bitmap(t,spr);

		spr.set("empty");
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onStopBeingCarried(by:Entity) {
		super.onStopBeingCarried(by);
		cd.setS("heroPickLock",0.5);
	}

	override function postUpdate() {
		super.postUpdate();
		spr.rotation = Math.cos(ftime*0.2 + uid)*0.1;

		if( isCarried() )
			addToLayer(Const.DP_BG);
		else
			addToLayer(Const.DP_MAIN);
	}
}

