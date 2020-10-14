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


		var g = new h2d.Graphics(spr);
		g.beginFill(0xffcc00);
		g.drawCircle(0,-3,6);
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
	}
}

