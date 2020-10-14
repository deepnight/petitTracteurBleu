package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];

	var data : World.Entity_Item;

	public function new(e:World.Entity_Item) {
		data = e;
		super(e.cx, e.cy);
		ALL.push(this);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onStopBeingCarried(by:Entity) {
		super.onStopBeingCarried(by);
		cd.setS("heroPickLock",0.5);
	}
}

