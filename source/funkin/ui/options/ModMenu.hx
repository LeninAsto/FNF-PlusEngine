package funkin.ui.options;

import backend.Mods;
import funkin.modding.PolymodHandler;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import polymod.Polymod.ModMetadata;
import funkin.ui.Page;

class ModMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var grpMods:FlxTypedGroup<ModMenuItem>;
  var enabledMods:Array<ModMetadata> = [];
  var detectedMods:Array<VSliceModMenuEntry> = [];

  var curSelected:Int = 0;
  var menuTop:Float = 0;

  public function new(menuTop:Float = 0):Void
  {
    super();
    this.menuTop = menuTop;

    grpMods = new FlxTypedGroup<ModMenuItem>();
    add(grpMods);

    refreshModList();
  }

  override function update(elapsed:Float)
  {
    if (FlxG.keys.justPressed.R) refreshModList();

    selections();

    if (controls.UI_UP_P) selections(-1);
    if (controls.UI_DOWN_P) selections(1);

    if (FlxG.keys.justPressed.SPACE && grpMods.members[curSelected] != null)
      grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;

    if (FlxG.keys.justPressed.I && curSelected != 0)
    {
      swapMods(curSelected, curSelected - 1);
      selections(-1);
    }

    if (FlxG.keys.justPressed.K && curSelected < grpMods.members.length - 1)
    {
      swapMods(curSelected, curSelected + 1);
      selections(1);
    }

    super.update(elapsed);
  }

  function selections(change:Int = 0):Void
  {
    if (detectedMods.length < 1) return;

    curSelected += change;

    if (curSelected >= detectedMods.length) curSelected = 0;
    if (curSelected < 0) curSelected = detectedMods.length - 1;

    for (txt in 0...grpMods.length)
    {
      if (txt == curSelected)
      {
        grpMods.members[txt].color = FlxColor.YELLOW;
      }
      else
        grpMods.members[txt].color = FlxColor.WHITE;
    }

    organizeByY();
  }

  function refreshModList():Void
  {
    while (grpMods.members.length > 0)
    {
      grpMods.remove(grpMods.members[0], true);
    }

    #if sys
    Mods.updateVSliceModList();
    var savedList = Mods.parseVSliceList();
    var metadataByDir:Map<String, ModMetadata> = [];

    for (metadata in PolymodHandler.getAllMods())
      metadataByDir.set(getModDirName(metadata), metadata);

    detectedMods = [];
    for (folder in savedList.all)
    {
      var metadata:Null<ModMetadata> = metadataByDir.get(folder);
      detectedMods.push({
        folder: folder,
        title: metadata != null ? metadata.title : folder,
        metadata: metadata
      });
    }

    trace('ModMenu: Detected ${detectedMods.length} mods');

    for (index in 0...detectedMods.length)
    {
      var modMetadata:VSliceModMenuEntry = detectedMods[index];
      var modName:String = modMetadata.title;
      var txt:ModMenuItem = new ModMenuItem(0, menuTop + 10 + (40 * index), 0, modName, 32);
      txt.text = modName;
      txt.daMod = modMetadata.folder;
      txt.modEnabled = savedList.enabled.contains(modMetadata.folder);
      grpMods.add(txt);
    }
    #end
  }

  public function saveVSliceList():Void
  {
    var list:ModsList = {enabled: [], disabled: [], all: []};

    for (item in grpMods.members)
    {
      if (item == null || item.daMod == null || item.daMod.trim().length < 1) continue;
      list.all.push(item.daMod);
      if (item.modEnabled) list.enabled.push(item.daMod);
      else list.disabled.push(item.daMod);
    }

    Mods.saveList(list, true);
    Mods.loadTopVSliceMod();
  }

  function organizeByY():Void
  {
    for (i in 0...grpMods.length)
    {
      grpMods.members[i].y = menuTop + 10 + (40 * i);
    }
  }

  function swapMods(a:Int, b:Int):Void
  {
    var oldText = grpMods.members[b];
    grpMods.members[b] = grpMods.members[a];
    grpMods.members[a] = oldText;

    var oldEntry = detectedMods[b];
    detectedMods[b] = detectedMods[a];
    detectedMods[a] = oldEntry;
  }

  function getModDirName(mod:ModMetadata):String
  {
    var dynamicMod:Dynamic = mod;
    var dirName:Null<String> = Reflect.field(dynamicMod, 'dirName');
    return dirName ?? mod.id;
  }
}

typedef VSliceModMenuEntry =
{
  var folder:String;
  var title:String;
  var metadata:Null<ModMetadata>;
}

class ModMenuItem extends FlxText
{
  public var modEnabled:Bool = false;
  public var daMod:String;

  public function new(x:Float, y:Float, w:Float, str:String, size:Int)
  {
    super(x, y, w, str, size);
  }

  override function update(elapsed:Float)
  {
    if (modEnabled) alpha = 1;
    else
      alpha = 0.5;

    super.update(elapsed);
  }
}
