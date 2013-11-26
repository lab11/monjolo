/*
 * @author: Brad Campbell <bradjc@umich.edu>
 */

#include "calibrate_border.h"

configuration CalibrateBorderC {
}

implementation {
  components CalibrateBorderP;

  components MainC;
  MainC.SoftwareInit -> CalibrateBorderP.SoftwareInit;

  components IPForwardingEngineP;
  IPForwardingEngineP.IPForward[ROUTE_IFACE_CALIB] -> CalibrateBorderP.IPForward;

  components IPStackC;
  CalibrateBorderP.ForwardingTable -> IPStackC.ForwardingTable;

  components UnixTimeC;
  CalibrateBorderP.UnixTime -> UnixTimeC.UnixTime;

}
