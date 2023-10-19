{ lib }:
{
  halalify =
    drv:
    drv.overrideAttrs (_old: {
      meta = _old.meta // {
        license = lib.licenses.free;
      };
    });
  haramify =
    drv:
    drv.overrideAttrs (_old: {
      meta = _old.meta // {
        license = lib.licenses.unfree;
      };
    });
}
