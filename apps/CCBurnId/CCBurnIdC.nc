
configuration CCBurnIdC { }
implementation {
  components CCBurnIdP as App;

  components MainC;
  App.Boot -> MainC.Boot;

  components LocalIeeeEui64C;
  App.LocalIeeeEui64 -> LocalIeeeEui64C.LocalIeeeEui64;

  components Fm25lbC;
  App.Fram -> Fm25lbC.Fm25lb;
}

