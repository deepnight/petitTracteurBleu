import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;
	public var controller : dn.legacy.Controller;
	public var ca : dn.legacy.Controller.ControllerAccess;

	public function new(s:h2d.Scene) {
		super();
		ME = this;

        createRoot(s);

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff<<24|0xffffff;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Resources
		#if(hl && debug)
		hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed();
        #end

        // Hot reloading
		#if debug
			hxd.res.Resource.LIVE_UPDATE = true;

			hxd.Res.data.watch(function() {
				delayer.cancelById("cdb");
				delayer.addS("cdb", function() {
					Data.load( hxd.Res.data.entry.getBytes().toString() );
					if( Game.ME!=null )
						Game.ME.onCdbReload();
				}, 0.2);
			});

			hxd.Res.world.world_ldtk.watch(function() {
				delayer.cancelById("led");
				delayer.addS("led", function() {
					if( Game.ME!=null )
						Game.ME.onLedReload( hxd.Res.world.world_ldtk.entry.getBytes().toString() );
				}, 0.2);
			});
		#end

		// Assets & data init
		Assets.init();
		new ui.Console(Assets.fontTiny, s);
		Lang.init("en");
		Data.load( hxd.Res.data.entry.getText() );

		// Game controller
		controller = new dn.legacy.Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(A, Key.UP, Key.Z, Key.W, Key.SPACE);
		controller.bind(SELECT, Key.R);
		controller.bind(START, Key.N);

		// Start
		if( dn.heaps.GameFocusHelper.isUseful() ) {
			new dn.heaps.GameFocusHelper(Boot.ME.s2d, Assets.fontMedium);
			delayer.addF( startGame, 1 );
		}
		else
			startGame();
	}

	public function startGame() {
		if( Game.ME!=null ) {
			Game.ME.destroy();
			dn.Process.updateAll(1);
			new Game();
		}
		else
			new Game();
	}

	override public function onResize() {
		super.onResize();

		// Auto scaling
		if( Const.AUTO_SCALE_TARGET_WID>0 )
			Const.SCALE = M.ceil( w()/Const.AUTO_SCALE_TARGET_WID );
		else if( Const.AUTO_SCALE_TARGET_HEI>0 )
			Const.SCALE = M.ceil( h()/Const.AUTO_SCALE_TARGET_HEI );

		Const.UI_SCALE = Const.SCALE;
	}

    override function update() {
		Assets.tiles.tmod = tmod;
        super.update();
    }
}