/* Returns a 64 bit unique ID based on the DS2411 unique ID chip, the 24 bit
 * OUI (mac address header), and a 16 bit platform specific ID. The non DS2411
 * constants are located in the PlatformIeeeEui64.h file in the platfrom
 * specific directory.
 *
 * This driver caches the unique ID after it is determined the first time.
 *
 * This driver first checks FRAM for its ID, and if that fails samples
 * the DS2411.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration LocalIeeeEui64C {
  provides {
  	interface LocalIeeeEui64;
  }
}

implementation {
  components LocalIeeeEui64P;
  components Ds2411C;
  components FM25L04BC;

  LocalIeeeEui64P.ReadId48 -> Ds2411C.ReadId48;
  LocalIeeeEui64P.Fram -> FM25L04BC.Fm25lb;

  LocalIeeeEui64 = LocalIeeeEui64P.LocalIeeeEui64;
}
