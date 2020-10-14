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

	override function update() {
		super.update();

		if( !isCarried() && hero.isAlive() && distCase(hero)<=1 )
			hero.startCarrying(this);
	}
}

