import dn.Process;
import hxd.Key;

class Game extends Process {
	public static var ME : Game;

	/** Game controller (pad or keyboard) **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	/** Particles **/
	public var fx : Fx;

	/** Basic viewport control **/
	public var camera : Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller : h2d.Layers;

	/** Level data **/
	public var level : Level;

	/** UI **/
	public var hud : ui.Hud;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;
	var slowMos : Map<String, { id:String, t:Float, f:Float }> = new Map();

	/** LEd world data **/
	public var world : World;

	public var hero : en.Hero;
	public var cart : en.Cart;
	public var teint : h2d.filter.ColorMatrix;
	var gameTimeS = 0.;
	var logo : HSprite;
	var sleepMask : HSprite;

	public var mouseX = -1.;
	public var mouseDown = false;
	var mouseDownTime = -1.;


	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_MAIN);
		scroller.filter = teint = new h2d.filter.ColorMatrix();

		world = new World();
		camera = new Camera();
		fx = new Fx();
		hud = new ui.Hud();

		sleepMask = Assets.tiles.h_get("sleepMask");
		root.add(sleepMask, Const.DP_TOP);
		sleepMask.colorize(C.hexToInt("#16162b"), 1);

		Boot.ME.s2d.addEventListener( onEvents );

		startLevel(0);
	}


	function onEvents(ev:hxd.Event) {
		switch ev.kind {
			case EPush: onMouseDown(ev);
			case ERelease: onMouseUp();
			case EMove:
			case EOver:
			case EOut: onMouseUp();
			case EWheel:
			case EFocus:
			case EFocusLost: onMouseUp();
			case EKeyDown:
			case EKeyUp:
			case EReleaseOutside: onMouseUp();
			case ETextInput:
			case ECheck:
		}
	}

	function onMouseDown(e:hxd.Event) {
		mouseDownTime = haxe.Timer.stamp();
		mouseDown = true;
		mouseX = e.relX;
	}

	function onMouseUp() {
		if( mouseDown && haxe.Timer.stamp()-mouseDownTime<=0.3 )
			hero.onShortPress( mouseX>=w()*0.5 ? 1 : -1 );

		mouseDown = false;
	}

	function onMouseMove(e:hxd.Event) {
		mouseX = e.relX;
	}


	function startLevel(idx:Int) {
		// Cleanup
		if( level!=null )
			level.destroy();

		for(e in Entity.ALL)
			e.destroy();
		gc();

		if( logo!=null )
			logo.remove();

		tw.completeAll();

		// Init
		level = new Level( idx, world.levels[idx] );
		gameTimeS = 0;
		camera.zoom = 1;

		sleepMask.alpha = 0;
		sleepMask.visible = false;

		// Create entities
		hero = new en.Hero( level.data.l_Entities.all_Hero[0] );
		camera.trackTarget( hero, true, 0, -Const.GRID*2 );
		cart = new en.Cart();

		for(e in level.data.l_Entities.all_Item)
			new en.Item(e.f_type, e.cx, e.cy);

		for(e in level.data.l_Entities.all_Home)
			new en.Home(e);

		for(e in level.data.l_Entities.all_ItemGenerator)
			new en.ItemGen(e);

		for(e in level.data.l_Entities.all_Bumper)
			new en.Bumper(e);

		fx.clear();
		hud.invalidate();

		// Logo
		logo = Assets.tiles.h_get("logo",0, 0.5,0.5);
		root.add(logo, Const.DP_UI);
		tw.createMs(logo.alpha, 0, 10000);
		cd.setS("logoArrival", 1.5);

		Process.resizeAll();
	}

	public inline function restartLevel() {
		startLevel(level.idx);
	}

	/**
		Called when the CastleDB changes on the disk, if hot-reloading is enabled in Boot.hx
	**/
	public function onCdbReload() {}
	public function onLedReload(json:String) {
		world.parseJson(json);
		restartLevel();
	}

	override function onResize() {
		super.onResize();
		scroller.setScale(Const.SCALE);
		if( logo!=null )
			logo.setScale(Const.SCALE);

		if( sleepMask!=null ) {
			sleepMask.scaleX = w()/sleepMask.tile.width;
			sleepMask.scaleY = h()/sleepMask.tile.height;
		}
	}


	function gc() {
		if( Entity.GC==null || Entity.GC.length==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		Boot.ME.s2d.removeEventListener( onEvents );

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		gc();
	}


	/**
		Start a cumulative slow-motion effect that will affect `tmod` value in this Process
		and its children.

		@param sec Realtime second duration of this slowmo
		@param speedFactor Cumulative multiplier to the Process `tmod`
	**/
	public function addSlowMo(id:String, sec:Float, speedFactor=0.3) {
		if( slowMos.exists(id) ) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		}
		else
			slowMos.set(id, { id:id, t:sec, f:speedFactor });
	}


	function updateSlowMos() {
		// Timeout active slow-mos
		for(s in slowMos) {
			s.t -= utmod * 1/Const.FPS;
			if( s.t<=0 )
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for(s in slowMos)
			targetGameSpeed*=s.f;
		curGameSpeed += (targetGameSpeed-curGameSpeed) * (targetGameSpeed>curGameSpeed ? 0.2 : 0.6);

		if( M.fabs(curGameSpeed-targetGameSpeed)<=0.001 )
			curGameSpeed = targetGameSpeed;
	}


	/**
		Pause briefly the game for 1 frame: very useful for impactful moments,
		like when hitting an opponent in Street Fighter ;)
	**/
	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
	}

	override function preUpdate() {
		super.preUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
	}

	override function postUpdate() {
		super.postUpdate();


		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();
		for(e in Entity.ALL) if( !e.destroyed ) e.finalUpdate();
		gc();

		// Update slow-motions
		updateSlowMos();
		baseTimeMul = ( 0.2 + 0.8*curGameSpeed ) * ( ucd.has("stopFrame") ? 0.3 : 1 );
		Assets.tiles.tmod = tmod;

		// Logo
		logo.x = Std.int( w()*0.5 );
		logo.y = Std.int( h()*0.88 ) + cd.getRatio("logoArrival")*h()*0.2;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.fixedUpdate();
	}

	override function update() {
		super.update();

		for(e in Entity.ALL) if( !e.destroyed ) e.update();

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			#if hl
			// Exit
			if( ca.isKeyboardPressed(K.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end

			#if debug
			// Level marks
			if( ca.isKeyboardPressed(K.M) ) {
				var allMarks = LevelMark.getConstructors();
				for( cx in 0...level.wid )
				for( cy in 0...level.hei ) {
					var i = 0;
					for( id in allMarks ) {
						var m = LevelMark.createByName(id);
						if( level.hasMark(m, cx,cy) )
							fx.markerText(cx,cy, id.substr(0,2), C.makeColorHsl(i/allMarks.length), 10 );
						i++;
					}
				}
			}

			// Force night
			if( ca.isKeyboardDown(K.N) )
				gameTimeS += 5*tmod;
			#end

			if( ca.isKeyboardPressed(K.R) && ca.isKeyboardDown(K.SHIFT) )
				startLevel(0);
		}

		gameTimeS += tmod/Const.FPS;

		if( !en.Item.hasAnyLeft() )
			gameTimeS += 1*tmod;

		// level.nightRatio = M.fclamp(gameTimeS/Const.MAX_GAME_TIME_S, 0, 1);
		level.rawNightRatio+=0.0004*tmod;
	}
}

