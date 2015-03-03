package ;

import snow.utils.ByteArray;
import snow.utils.Float32Array;
import luxe.Input;
import luxe.Text;
import luxe.Vector;
import luxe.Color;
import luxe.Input;
import luxe.Entity;
import luxe.Sprite;
import luxe.Rectangle;
import luxe.Parcel;
import luxe.ParcelProgress;
import phoenix.Batcher;
import phoenix.BitmapFont;

import temp.Particles;
import temp.importers.particledesigner.ParticleDesigner;
import Luxe.Ev;

// TODO:
// show.platform.web.utils.ByteArray::set_length - ... else if (allocated > value) { snowResizeBuffer(allocated = value); } - remove

class Main extends luxe.Game {
    var is_loaded:Bool = false;
    var is_reset_called:Bool = false;
    var info_text:Text;
    var particle_systems:Array<ParticleSystem> = [];
    var current_index:Int = 0;
    var mouse_pressed:Bool = false;

    override function ready() {
        Luxe.renderer.clear_color = (new Color()).rgb(0x0a0b29);
        var parcel = new Parcel();

        for (id in app.app.assets.list.keys()) {
            switch (app.app.assets.list[id].type) {
                case "fnt":
                    parcel.add_font(id);

                case "image":
                    parcel.add_texture(id);

                case "json":
                    parcel.add_json(id);

                case "plist" | "pex" | "lap":
                    parcel.add_text(id);
            }
        }

        var parcel_progress = new ParcelProgress({
            parcel: parcel,
            background: new Color(1.0, 1.0, 1.0, 0.85),
            oncomplete: onloaded
        });

        parcel.load();
    }

    function onloaded(_) {
        add_particle_system("assets/particles/galaxy.pex");
        add_particle_system("assets/particles/duman-2.plist");
        add_particle_system("assets/particles/ex.plist");
        add_particle_system("assets/particles/snow.lap");
        add_particle_system("assets/particles/fancyflame.json");
        add_particle_system("assets/particles/fire-4.json");
        add_particle_system("assets/particles/heart.pex");
        add_particle_system("assets/particles/fountain.lap");
        add_particle_system("assets/particles/bubbles.json");
        add_particle_system("assets/particles/fire.plist");
        add_particle_system("assets/particles/frosty-blood.plist");
        add_particle_system("assets/particles/line-of-fire.plist");
        add_particle_system("assets/particles/trippy.plist");
        add_particle_system("assets/particles/sun.plist");
        add_particle_system("assets/particles/iris.plist");
        add_particle_system("assets/particles/hyperflash.plist");
        add_particle_system("assets/particles/dust.plist");

        particle_systems[0].on(Ev.reset, function(_) {
            is_reset_called = true;

            if (is_loaded) {
                update_info();
            }
        });

        Luxe.loadFont("assets/fonts/font.fnt", null, onfontloaded);
    }

    function onfontloaded(font:BitmapFont):Void {
        add_button(font, 20, 20, 100, 30, "PREV");
        add_button(font, 220, 20, 100, 30, "NEXT");

        info_text = new Text({
            bounds: new Rectangle(120, 20, 100, 30),
            point_size: 10,
            font: font,
            color: new Color(1.0, 1.0, 1.0, 1.0),
            align: center,
            align_vertical: center,
        });

        new Text({
            text: "Click to emit",
            bounds: new Rectangle(20, 55, 300, 30),
            point_size: 10,
            font: font,
            color: new Color(1.0, 1.0, 1.0, 1.0),
            align: center,
            align_vertical: center,
        });

        info_text.text = "...";

        if (is_reset_called) {
            update_info();
        }

        is_loaded = true;
    }

    function add_button(font:BitmapFont, x:Float, y:Float, w:Float, h:Float, s:String):Void {
        var rect = new Rectangle(x, y, w, h);

        Luxe.draw.box({
            rect: rect,
            color: (new Color()).rgb(0xfab91e),
        });

        new Text({
            text: s,
            bounds: rect,
            point_size: 10,
            font: font,
            color: new Color(0.0, 0.0, 0.0, 1.0),
            align: center,
            align_vertical: center,
        });
    }

    function add_particle_system(id:String):Void {
        var ps = new ParticleSystem();
        ps.enabled = false;
        ps.paused = true;
        ps.add_emitter(ParticleDesigner.parse(id, particle_systems.length + 10));
        particle_systems.push(ps);
    }

    function update_info():Void {
        info_text.text = '${current_index + 1}/${particle_systems.length}';
        particle_systems[current_index].pos.set_xy(Luxe.screen.mid.x, Luxe.screen.mid.y);
        particle_systems[current_index].start();
    }

    override function onmousedown(e:MouseEvent) {
        if (!is_loaded) {
            return;
        }

        if (e.y >= 20 && e.y <= 50) {
            if (e.x >= 20 && e.x <= 120) {
                particle_systems[current_index].stop();
                current_index = (current_index - 1 + particle_systems.length) % particle_systems.length;
                update_info();
                return;
            }

            if (e.x >= 220 && e.x <= 320) {
                particle_systems[current_index].stop();
                current_index = (current_index + 1) % particle_systems.length;
                update_info();
                return;
            }
        }

        mouse_pressed = true;
        particle_systems[current_index].pos.set_xy(e.x, e.y);
        particle_systems[current_index].start();
    }

    override function onmousemove(e:MouseEvent) {
        if (!is_loaded || !mouse_pressed) {
            return;
        }

        particle_systems[current_index].pos.set_xy(e.x, e.y);
        particle_systems[current_index].start();
    }

    override function onmouseup(e:MouseEvent) {
        if (!is_loaded || !mouse_pressed) {
            return;
        }

        particle_systems[current_index].pos.set_xy(e.x, e.y);
        mouse_pressed = false;
    }

    override function onkeyup(e:KeyEvent) {
        if (e.keycode == Key.escape) {
            Luxe.shutdown();
        }
    }
}
