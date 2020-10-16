package en;

class Bumper extends Entity {
	public static var ALL : Array<Bumper> = [];

	var data : World.Entity_Bumper;

	public function new(e:World.Entity_Bumper) {
		data = e;
		super(e.cx, e.cy);
		ALL.push(this);
		spr.set("bumperOff");
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function onUse() {
		game.addSlowMo("bumper", 0.5, 0.7);
		cd.setS("open",0.5);
		spr.set("bumperOut");
		setSquashX(0.5);
		fx.bumper(footX, footY);
	}

	override function update() {
		super.update();
		if( !cd.has("open") && spr.groupName=="bumperOut" ) {
			spr.set("bumperOff");
			setSquashY(0.5);
		}
	}

}

