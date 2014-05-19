/* Generic interface for the MicroCrystal line of RTCs.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

interface RVRTC {
  command error_t readTime ();
  command error_t setTime (uint8_t seconds,
                           uint8_t minutes,
                           uint8_t hours,
                           uint8_t days,
                           month_e month,
                           uint16_t year,
                           day_e weekday);

  event void readTimeDone (error_t error,
                           uint8_t seconds,
                           uint8_t minutes,
                           uint8_t hours,
                           uint8_t days,
                           month_e month,
                           uint16_t year,
                           day_e weekday);
  event void setTimeDone (error_t error);
}
