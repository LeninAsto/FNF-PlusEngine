# hxscript Integration

Plus Engine's classed HScript backend is powered by `hxscript`.

Credit:

- Library: `hxscript`
- Author: AutisticLulu
- Fork used by this engine: `https://github.com/Psych-Plus-Team/hxscript.git`

This folder only contains the engine integration layer: Psych/Plus-specific
globals, interpreter behavior, and migration glue. The upstream library itself
is still resolved from the configured Haxe/haxelib environment.

Plus Engine expects `hxscript` to be installed from the Psych-Plus-Team fork:

```powershell
haxelib git hxscript https://github.com/Psych-Plus-Team/hxscript.git
```

The Psych-Plus-Team fork already includes the scripted bridge null `ComplexType`
guard. The patch is also stored in
`source/scripting/hscript/patches/hxscript-null-complex-type.patch` for reference.
