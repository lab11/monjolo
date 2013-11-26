/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */

configuration HplCC2420FbC {
	provides {
		interface Resource as SpiResource;
		interface FastSpiByte;
		interface GeneralIO as CCA;
		interface GeneralIO as CSN;
		interface GeneralIO as FIFO;
		interface GeneralIO as FIFOP;
		interface GeneralIO as RSTN;
		interface GeneralIO as SFD;
		interface GeneralIO as VREN;
		interface GpioCapture as SfdCapture;
		interface GpioInterrupt as FifopInterrupt;
		interface LocalTime<TRadio> as LocalTimeRadio;

		interface Alarm<TRadio,uint16_t>;
    //interface Alarm<TRadioAlarm,uint16_t>; // New
	}
}
implementation {

	components new Msp430Spi0C() as SpiC, MotePlatformC, HplMsp430GeneralIOC as IO;

	SpiResource = SpiC.Resource;
	FastSpiByte = SpiC;

  components new Msp430GpioC() as CCAM;
  components new Msp430GpioC() as CSNM;
  components new Msp430GpioC() as FIFOM;
  components new Msp430GpioC() as FIFOPM;
  components new Msp430GpioC() as RSTNM;
  components new Msp430GpioC() as SFDM;
  components new Msp430GpioC() as VRENM;

  CCAM -> GeneralIOC.Port14;
  CSNM -> GeneralIOC.Port42;
  FIFOM -> GeneralIOC.Port13;
  FIFOPM -> GeneralIOC.Port10;
  RSTNM -> GeneralIOC.Port46;
  SFDM -> GeneralIOC.Port41;
  VRENM -> GeneralIOC.Port45;

  CCA = CCAM;
  CSN = CSNM;
  FIFO = FIFOM;
  FIFOP = FIFOPM;
  RSTN = RSTNM;
  SFD = SFDM;
  VREN = VRENM;

  components HplMsp430GeneralIOC as GeneralIOC;
  components Msp430TimerC;
  components new GpioCaptureC() as CaptureSFDC;
  CaptureSFDC.Msp430TimerControl -> Msp430TimerC.ControlB1;
  CaptureSFDC.Msp430Capture -> Msp430TimerC.CaptureB1;
  CaptureSFDC.GeneralIO -> GeneralIOC.Port41;
  SfdCapture = CaptureSFDC;

  components HplMsp430InterruptC;
  components new Msp430InterruptC() as FifopInterruptC;
  FifopInterruptC.HplInterrupt -> HplMsp430InterruptC.Port10;
  FifopInterrupt= FifopInterruptC;

	components LocalTime32khzC;
	LocalTimeRadio = LocalTime32khzC.LocalTime;

	components new Alarm32khz16C() as AlarmC;
  //components new AlarmMicro16C() as AlarmC;   // New
	Alarm = AlarmC;

}
