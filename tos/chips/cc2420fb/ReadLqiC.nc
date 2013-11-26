
/* Needed for BLIP
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration ReadLqiC {
  provides {
    interface ReadLqi;
  }
}

implementation {
  components CC2420FbDriverLayerC;
  ReadLqi = CC2420FbDriverLayerC.ReadLqi;
}
