#include "printf.h"

configuration CCReadFramC { }
implementation {
  components CCReadFramP as App;

  components MainC;
  App.Boot -> MainC.Boot;

  components Fm25lbC;
  App.Fram -> Fm25lbC.Fm25lb;

  components new TimerMilliC();
  App.Timer -> TimerMilliC.Timer;

  components PrintfC;
  components SerialStartC;
}

